#
# Copyright (c) 2026 Oracle, Inc.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
import argparse
import yaml
import logging
import logging.handlers
import os
import sys
import json
from datetime import datetime, timezone
from dateutil import parser as date_parser  # requires python-dateutil
from vcenter_client import VCenterClient
from oci_client import OCIClient
from constants import VC_TO_OCI_ENTITY_TYPE, EVENT_ENTITY_TYPE_MAP, MONITORED_EVENTS
from utils import validate_basedir, get_checkpoint_file, setup_logging, load_config

# Cross-version datetime ISO parser
try:
    parse_dt = datetime.fromisoformat  # Python 3.7+
except AttributeError:
    from dateutil import parser
    parse_dt = parser.parse


EVENTS_CHECKPOINT_FILE = "vmware-events-checkpoint"

# ------------------- Helpers -------------------
def get_event_time(event):
    """
    Extract a datetime from a vCenter event.
    Prefer createdTime, then timestamp, else None.
    Normalize to UTC and make it tz-aware.
    """
    ts = getattr(event, "createdTime", None) or getattr(event, "timestamp", None)
    if not ts:
        return None
    if ts.tzinfo is None:
        return ts.replace(tzinfo=timezone.utc)
    return ts.astimezone(timezone.utc)

def get_event_type(event):
    return getattr(event, "type", None) or event.__class__.__name__

def load_checkpoint(checkpoint_file):
    """Load last processed event time from checkpoint."""
    try:
        with open(checkpoint_file, "r") as f:
            data = json.load(f)
            last_time = date_parser.parse(data["last_event_time"])
            if last_time.tzinfo is None:
                last_time = last_time.replace(tzinfo=timezone.utc)
            return last_time
    except FileNotFoundError:
        return None
    except Exception as e:
        logging.warning(f"Failed to load checkpoint: {e}")
        return None

def save_checkpoint(checkpoint_file:str, dt: datetime):
    try:
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        with open(checkpoint_file, "w") as f:
            json.dump({"last_event_time": dt.isoformat()}, f)
    except Exception as e:
        logging.error(f"Failed to save checkpoint: {e}")

def mor_to_dict(mor):
    # convert ManagedObjectReference to safe dict
    if not mor:
        return None

    return {
        "name": getattr(mor, "name", None),
        "moid": getattr(mor, "_moId", None),
        "type":mor.__class__.__name__
    }

def datetime_to_str(dt):
    if not dt:
        return None
    return dt.isoformat()

def parse_event(event):
    # convert vim.event.Event -> JSON-safe dict

    event_type = get_event_type(event)
    message = getattr(event, "fullFormattedMessage", "")
    created_time = datetime_to_str(getattr(event, "createdTime", datetime.utcnow()))
    user = getattr(event, "userName", "unknown")

    entity_name = (
        getattr(getattr(event, "vm", None), "name", None)
        or getattr(getattr(event, "host", None), "name", None)
        or getattr(getattr(event, "computeResource", None), "name", None)
        or getattr(getattr(event, "datastore", None), "name", None)
        or getattr(getattr(event, "resourcePool", None), "name", None)
        or getattr(getattr(event, "dc", None), "name", None)
        or getattr(getattr(event, "vcenter", None), "name", None)
        or "Unknown"
    )

    # Map event type to entity type
    entity_type = EVENT_ENTITY_TYPE_MAP.get(event_type, "VMware vSphere vCenter")

    data = {
        "eventType": event_type,
        "entityName": entity_name,
        "entityType": entity_type,
        "user": user,
        "time": created_time,
        "message": message,
    }

    #common entity references
    for attr in {
        "vm",
        "host",
        "datastore",
        "computeresource",
        "dc",
        "resourcePool",
        "network",
        "folder"
    }:
        if hasattr(event, attr):
            data[attr] = mor_to_dict(getattr(event, attr))
    
    #Alarm specific fields 
    if hasattr(event, "sourceHost"):
        if hasattr(event, "alarm"):
            data["alarm"] = mor_to_dict(event.alarm)
        data["oldStatus"] = getattr(event, "oldStatus", None)
        data["newStatus"] = getattr(event, "newStatus", None)

    # Migration Specific
    if hasattr(event, "sourceHost"):
        data["sourceHost"] = mor_to_dict(event.sourceHost)

    if hasattr(event, "destHost"):
        data["destHost"] = mor_to_dict(event.sourceHost)

    return data

# ------------------- Prepare Log Event -------------------
def prepare_log_events(oci_client, parsed_events, vcenter_ocid, source):
    payload = {
        "metadata": {},
        "logEvents": []
    }
    for event in parsed_events:
        entity_type = event.get("entityType")
        entity_name = event.get("entityName")
        entity_id = oci_client.find_entity(entity_type, entity_name)
        if not entity_id:
            logging.warning(f"No entity id found in cache for {entity_type}::{entity_name}")
            entity_id = vcenter_ocid

        payload["logEvents"].append({
            "metadata": {},
            "entityType": entity_type,
            "entityId": entity_id,
            "logSourceName": source,
            "logPath": "/vmware/events",
            "logRecords": [
                json.dumps(event)
#                json.dumps({
#                    "eventType": parsed_event.get("eventType"),
#                    "entityName": entity_name,
#                    "time": parsed_event.get("time"),
#                    "message": parsed_event.get("message"),
#                })
            ]
        }
    )
    return payload

# ------------------- Main -------------------
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-dir", required=True, help="Base directory containing config.yaml, logs/, and state/")
    parser.add_argument("--dry-run", action="store_true", help="Run without making changes to OCI")
    parser.add_argument("--collect-only", action="store_true", help="Collect alarms but do not post to LA")
    args = parser.parse_args()

    basedir = validate_basedir(args.base_dir)
    setup_logging(basedir, "vmware-events")

    logging.info("Starting VMware alarms collector...")

    config_file = os.path.join(basedir, "config.yaml")
    # Load config
    config = load_config(config_file)

    is_dry_run = args.dry_run or config.get("dry_run", False)
    logging.info("Starting VMWare events collector: dry_run=%s", is_dry_run)

    # Initialize clients
    oci_cfg = config.get("oci", {})
    vconfig = config.get("vcenter")
    host = vconfig.get("host")
    ociClient = OCIClient(oci_cfg, vcenter_host=host, dry_run=is_dry_run)
    vcenter_ocid = ociClient.get_vcenter_entity_id()
    logging.info("vCenter entity id: %s", vcenter_ocid)
    if not vcenter_ocid:
        logging.error("Did not find vCenter entity  in OCI LA!")
        sys.exit(1)

    user = ociClient.get_secret(vconfig.get("user_secret_ocid"))
    password = ociClient.get_secret(vconfig.get("password_secret_ocid"))
    port = vconfig.get("port", "443")
    source = oci_cfg["events_source"]

    checkpoint_file = get_checkpoint_file(basedir, EVENTS_CHECKPOINT_FILE)
    vcenterClient = VCenterClient(host, port, user, password)
    last_time = load_checkpoint(checkpoint_file)

    logging.info("Fetching entity OCID map from OCI Log Analytics API")
    try:
        entity_map = ociClient.get_entity_cache()
        logging.info(f"Fetched {len(entity_map)} entities from OCI LA")
    except Exception as e:
        logging.error(f"Failed to fetch entity mapping: {e}")
        return

    # Fetch events
    events = vcenterClient.fetch_events(since_time=last_time)
    logging.info(f"Fetched {len(events)} events")
    
    latest_event_time = None
    parsed_events = []

    for event in events:
        event_type = get_event_type(event)
#        if event_type not in MONITORED_EVENTS:
#            logging.debug(f"Skipping unmonitored event type: {event_type}")
#            continue
        parsed = parse_event(event)
        logging.info(
            f"{parsed['eventType']} | {parsed['entityName']} | {parsed['message']}"
        )

        parsed_events.append(parsed)

        # Track latest timestamp
        ts = get_event_time(event)
        if not ts:
            logging.warning(f"Event {parsed.get('eventType')} has no timestamp, skipping")
            continue

        if not latest_event_time or ts > latest_event_time:
            latest_event_time = ts

    logging.info("Generating upload payload...")
    payload = prepare_log_events(ociClient, parsed_events, vcenter_ocid, source)

    # Upload batched events
    if parsed_events:
        if is_dry_run:
            # Save locally
            logs_dir = os.path.join(basedir, "logs")
            payload_file = os.path.join(logs_dir, "events_payload.json")
            with open(payload_file, "w") as f:
                json.dump(payload, f, indent=2)
            logging.info(f"Payload written to {payload_file}")
            print(f"Payload written to {payload_file}")
            if collect_only:
                logging.info("DRY run mode: exiting without uploading to LA")
                print("DRY run mode: exiting without uploading to LA")
                return
        else:
            ociClient.upload_log_events_file(payload)
            logging.info(f"Uploaded Events to OCI LA.")
            # Save checkpoint 
            if latest_event_time:
                save_checkpoint(checkpoint_file, latest_event_time)


if __name__ == "__main__":
    main()
