import os
import sys
import argparse
import json
import yaml
import logging
from datetime import datetime, timezone, timedelta

from vcenter_client import VCenterClient
from oci_client import (
    OCIClient,
    make_entity_key,
    normalize_entity_type
)

from constants import INTERESTED_ENTITY_TYPES, ALARMS_FILE, ALARMS_PAYLOAD_FILE
from synthetic_alarms import generate_synthetic_alarms_for_cache
from utils import validate_basedir, get_checkpoint_file, setup_logging, load_config

def utc_now_iso() -> str:
    return datetime.utcnow().replace(tzinfo=timezone.utc).isoformat()


def parse_iso_datetime(value):
    if value is None:
        return None
    if isinstance(value, datetime):
        return value
    if isinstance(value, str):
        dt = datetime.fromisoformat(value)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    raise ValueError(f"Unsupported datetime value: {value}")

def load_checkpoint(path):
    if not os.path.exists(path):
        logging.info("No checkpoint found, fetching all alarms")
        return None, None

    try:
        with open(path, "r") as f:
            data = json.load(f)

        last_time = parse_iso_datetime(data.get("last_time"))
        last_event_key = data.get("last_event_key")

        logging.info(
            "Loaded checkpoint: last_time=%s last_event_key=%s",
            last_time,
            last_event_key,
        )

        return last_time, last_event_key

    except Exception as e:
        logging.warning(f"Failed to read checkpoint: {e}")
        return None, None

def save_checkpoint(path, alarms):
    if not alarms:
        return

    last_event = max(
        alarms,
        key=lambda a: (a.createdTime, getattr(a, "key", 0))
    )

    dt = last_event.createdTime
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)

    checkpoint = {
        "last_time": dt.isoformat(),
        "last_event_key": getattr(last_event, "key", 0),
    }

    try:
        with open(path, "w") as f:
            json.dump(checkpoint, f)
        logging.info(f"Saved checkpoint: {checkpoint}")

    except Exception as e:
        logging.error(f"Failed to save checkpoint: {e}")

def build_log_events(alarms, entity_cache, log_source_name):
    """
    Convert vCenter alarms into OCI Log Analytics logEvents payloads
    and also return normalized alarms for local collection.
    """
    payload = {
        "metadata": {},
        "logEvents": []
    }

    collected = []
    interested_map = {k.lower(): v for k, v in INTERESTED_ENTITY_TYPES.items()}

    for alarm in alarms:
        try:
            entity_ref = str(getattr(alarm.entity, "entity", ""))
            entity_name = getattr(alarm.entity, "name", "unknown")

            # Extract entity type from entity_ref
            if ":" in entity_ref:
                raw_type, entity_id = entity_ref.split(":", 1)
                entity_type = normalize_entity_type(raw_type.replace("vim.", ""))
            else:
                entity_type = "unknown"
                entity_id = None

            la_entity_type = interested_map.get(entity_type.lower())
            #if not la_entity_type:
            #    logging.debug(f"Skipping unsupported entity type: {entity_type}")
            #    continue

            # Lookup OCI entity OCID from cache
            cache_key = make_entity_key(la_entity_type, entity_name)
            entity_ocid = entity_cache.get(cache_key)

            alarm_obj = getattr(alarm, "alarm", None)
            alarm_name = getattr(alarm_obj, "name", None) if alarm_obj else None
            event_key = getattr(alarm, "key", None)

            if entity_ref:
                entity_ref = str(entity_ref).strip("'")
            # Stable identifier per alarm per entity
            alarm_instance_key = f"{entity_ref}-{alarm_name}" if entity_ref and alarm_name else None


            normalized_alarm = {
                #"eventType": type(alarm).__name__,
                "eventType": getattr(alarm, "eventType", type(alarm).__name__),
                "entityType": entity_type,
                "entityName": entity_name,
                "fullFormattedMessage": getattr(alarm, "fullFormattedMessage", ""),
                "createdTime": alarm.createdTime.isoformat() if getattr(alarm, "createdTime", None) else None,
                "ociEntityType": la_entity_type,

                # Alarm-specific
                "alarmName": alarm_name,
                "statusFrom": getattr(alarm, "from", None),
                "statusTo": getattr(alarm, "to", None),
                "userName": getattr(alarm, "userName", None),
                "alarmInstanceKey": alarm_instance_key,
                "eventKey": event_key,
            }

            # Build log event for OCI
            payload["logEvents"].append(
                {
                    "metadata": {},
                    "entityType": la_entity_type,
                    "entityId": entity_ocid,
                    "logPath": "vcenter/alarm",
                    "logSourceName": log_source_name,
                    "logRecords": [json.dumps(normalized_alarm, ensure_ascii=False)]
                }
            )

            # For collected alarms file
            collected.append(normalized_alarm)

        except Exception as e:
            logging.error(f"Error processing alarm: {e}", exc_info=True)

    return payload, collected

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-dir", required=True, help="Base directory containing config.yaml, logs/, and state/")
    parser.add_argument("--dry-run", action="store_true", help="Store payload locally instead of uploading")
    args = parser.parse_args()

    basedir = validate_basedir(args.base_dir)
    setup_logging(basedir, "vmware-alarms")


    config_file = os.path.join(basedir, "config.yaml")
    # Load config
    config = load_config(config_file)

    is_dry_run = args.dry_run or config.get("dry_run", False)
    logging.info("Starting VMWare alarms collector: dry_run=%s", is_dry_run)

    oci_config = config.get("oci")
    log_source_name=oci_config["alarms_source"]

    vconfig = config.get("vcenter")
    host = vconfig.get("host")
    port = vconfig.get("port", "443")

    oci_client = OCIClient(oci_config, vcenter_host=host, dry_run=is_dry_run)

    logging.info("Fetching entity OCID map from OCI Log Analytics API")
    try:
        entity_map = oci_client.get_entity_cache()
        logging.info(f"Fetched {len(entity_map)} entities from OCI LA")
    except Exception as e:
        logging.error(f"Failed to fetch entity mapping: {e}")
        return

    user = oci_client.get_secret(vconfig.get("user_secret_ocid"))
    password = oci_client.get_secret(vconfig.get("password_secret_ocid"))
    vcenter_client = VCenterClient(host, port, user, password)

    checkpoint_file = get_checkpoint_file(basedir, "vmware-alarms-checkpoint")

    # Load checkpoint (last alarm time)
    last_time, last_event_key = load_checkpoint(checkpoint_file)
    if last_time:
        logging.info(f"Resuming alarms collection from {last_time}")
    else:
        logging.info("No checkpoint found, fetching all alarms")


    vcenter_client.connect()
    # Fetch alarms from vCenter
    alarms = vcenter_client.fetch_alarms(start_time=last_time, checkpoint_event_key=last_event_key, max_events=5000)

    if not alarms:
        logging.info("No new alarms found in vcenter")

        use_synthetic_alarms = config.get("use_synthetic_alarms", False)
        if not use_synthetic_alarms:
            return

        alarms = generate_synthetic_alarms_for_cache(
            entity_cache=entity_map,
            count=2  # number of synthetic alarms per entity
        )
        logging.info("Generated %s synthetic alarms", len(alarms))


    # Build payload
    payload, collected_alarms = build_log_events(
        alarms,
        entity_map,
        log_source_name=log_source_name
    )

    # Save alarms

    logs_dir = os.path.join(basedir, "logs")
    alarms_file = os.path.join(logs_dir, ALARMS_FILE)
    with open(alarms_file, "w") as f:
        json.dump(collected_alarms, f, indent=2)

    logging.info(f"Saved {len(alarms)} alarms to {ALARMS_FILE}")

    payload_file = os.path.join(logs_dir, ALARMS_PAYLOAD_FILE)
    with open(payload_file, "w") as f:
        json.dump(payload, f, indent=2)
        logging.info(f"Payload saved to {ALARMS_PAYLOAD_FILE}")

    if is_dry_run:
        logging.info("DRY run mode enabled. Skipping upload to OCI.")
    else:
        responses = oci_client.upload_log_events_file(
            payload=payload
        )
        logging.info(f"Uploaded Alarm Events to OCI LA.")
        # Update checkpoint with latest alarm time if uploaded to OCI
        save_checkpoint(checkpoint_file, alarms)


if __name__ == "__main__":
    main()

