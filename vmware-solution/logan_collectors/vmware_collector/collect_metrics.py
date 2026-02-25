# main.py
import argparse
import logging
import json
import os
import random
import yaml
from datetime import datetime, timezone
from typing import Dict, Any, List

from vcenter_client import VCenterClient
from oci_client import OCIClient, make_entity_key, find_matching_ocid
from constants import SUPPORTED_ENTITY_TYPES, VC_TO_OCI_ENTITY_TYPE
from utils import validate_basedir, setup_logging, load_config

# Normalize LA entity type for matching
entity_type_map = {
    "vmware vsphere vm": "Vmware_VM_INSTANCE",
    "vmware vsphere cluster": "Vmware_CLUSTER",
    "vmware vsphere esxi host": "Vmware_ESXI_HOST",
    "vmware vsphere datastore": "Vmware_DATASTORE",
    "vmware vsphere data store": "Vmware_DATASTORE",
    "vmware vsphere network": "Vmware_NETWORK",
    "vmware vsphere data center": "VMware_DATA_CENTER",
    # Add other mappings if needed
}

def utc_now_iso() -> str:
    return datetime.utcnow().replace(tzinfo=timezone.utc).isoformat()

def augment_with_fake_metrics(collected: Dict[str, List[Dict[str, Any]]],
                              entity_map: Dict[str, str]) -> Dict[str, List[Dict[str, Any]]]:
    """
    Augments `collected` with fake metrics for entities in entity_map
    that are missing from the real collection. Does not alter existing real metrics.
    """

    for entity_key, ocid in entity_map.items():
        if "::" not in entity_key:
            continue
        la_type_raw, entity_name = entity_key.split("::", 1)
        la_type_norm = la_type_raw.strip().lower()
        entity_name = entity_name.strip().lower()
        logging.info("Processing missing metrics for entity_key=%s  entity=%s", entity_key, entity_name)

        # Map to exact type
        la_type = entity_type_map.get(la_type_norm)
        if not la_type:
            logging.info(f"Unknown entity type for {entity_key}, skipping")
            continue

        logging.info("Processing missing metrics for la_type=%s  entity=%s", la_type, entity_name)
        
        # Skip if metrics already exist
        existing_keys = {
            make_entity_key(m.get("entity_type", ""), m.get("name", ""))
            for etype, metrics in collected.items()
                for m in metrics
                    if isinstance(m, dict) and "entity_type" in m and "name" in m
        }

        logging.info("Created existing keys list")
        key = make_entity_key(la_type, entity_name)
        if key in existing_keys:
            logging.info("Metrics already exists for key=%s", key)
            continue

        ts = utc_now_iso()
        fake_entry = {"name": entity_name, "timestamp": ts, "entity_ocid": ocid, "entity_type": la_type }

        # generate realistic fake metrics based on type
        if la_type == "Vmware_VM_INSTANCE":
            # VM instance
            fake_entry.update({
                "cpu_capacity_ghz": 4,
                "cpu_used_ghz": round(random.uniform(0.1, 3.5), 2),
                "cpu_usage_percent": round(random.uniform(5, 90), 2),
                "memory_capacity_gb": 16,
                "memory_used_gb": round(random.uniform(1, 15), 2),
                "memory_usage_percent": round(random.uniform(10, 95), 2),
            })

        elif la_type == "Vmware_ESXI_HOST":
            fake_entry.update({
                "cpu_capacity_ghz": 64,
                "cpu_used_ghz": round(random.uniform(5, 60), 2),
                "cpu_usage_percent": round(random.uniform(10, 90), 2),
                "memory_capacity_gb": 512,
                "memory_used_gb": round(random.uniform(50, 450), 2),
                "memory_usage_percent": round(random.uniform(10, 95), 2),
            })

        elif la_type == "Vmware_CLUSTER":
            fake_entry.update({
                "num_hosts": 2,
                "num_vms": 10,
                "cpu_capacity_ghz": 500,
                "cpu_used_ghz": round(random.uniform(50, 450), 2),
                "cpu_usage_percent": round(random.uniform(10, 90), 2),
                "memory_capacity_gb": 4096,
                "memory_used_gb": round(random.uniform(500, 3500), 2),
                "memory_usage_percent": round(random.uniform(10, 95), 2),
            })

        elif la_type == "Vmware_DATASTORE":
            capacity_tb = round(random.uniform(10, 100), 2)
            used_tb = round(random.uniform(1, capacity_tb), 2)
            free_tb = capacity_tb - used_tb
            usage_pct = round((used_tb / capacity_tb) * 100, 2) if capacity_tb else None
            fake_entry.update({
                "storage_capacity_tb": capacity_tb,
                "storage_used_tb": used_tb,
                "storage_free_tb": free_tb,
                "storage_usage_percent": usage_pct,
                "accessible": True,
                "url": f"http://example.com/datastore/{entity_name}"
            })

        elif la_type == "VMware_DATA_CENTER":
            fake_entry.update({
                "clusters_count": 2,
                "hosts_count": 4,
                "datastores_count": 2,
                "networks_count": 20,
                "vms_count": 20
            })

        logging.info("Adding synthetic metrics for la_type=%s", la_type)
        if la_type in collected:
            collected[la_type].append(fake_entry)
        else:
            collected[la_type] = [fake_entry]
    
        logging.info("Added synthetic metrics for la_type=%s", la_type)

    for dc_metric in collected.get("VMware_DATA_CENTER", []):
        dc_metric.update({
            "clusters_count": 2,
            "hosts_count": 4,
            "datastores_count": 2,
            "networks_count": 20,
            "vms_count": 20
        })

    # Override Cluster metrics
    for cluster_metric in collected.get("Vmware_CLUSTER", []):
        cluster_metric.update({
            "num_hosts": 2,
            "num_vms": 10
        })

    return collected

def generate_la_payload(
    collected: Dict[str, Any],
    entity_map: Dict[str, str],
    source: str
) -> Dict[str, Any]:
    """
    Generates Log Analytics payload in required JSON format.
    Only collects metrics for entities that have a corresponding OCID.
    """
    payload = {
        "metadata": {
        },
        "logEvents": []
    }

    for etype, items in collected.items():
        la_entity_type = VC_TO_OCI_ENTITY_TYPE.get(etype, etype)
        for m in items:
            name = m.get("name")
            ocid = find_matching_ocid(entity_map, etype, name)
            logging.info(f"found OCID mapping for {etype}::{name} {ocid}")
            if not ocid:
                logging.debug(f"No OCID mapping found for {etype}::{name}, skipping metrics.")
                continue  # Skip entities without OCID

            log_record = json.dumps({k: v for k, v in m.items() if k != "name"})

            event = {
                "metadata": {
                },
                "entityType": la_entity_type,
                "entityId": ocid,
                "logSourceName": source,
                "logPath": f"/vcenter/metrics/{etype}/{name}",
                "logRecords": [log_record]
            }
            payload["logEvents"].append(event)

    return payload

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-dir", required=True, help="Base directory containing config.yaml, logs/, and state/")
    parser.add_argument("--dry-run", action="store_true", help="Store payload locally instead of uploading")
    parser.add_argument("--collect-only", action="store_true", help="Collect metrics/entities but do not post to LA")
    args = parser.parse_args()

    basedir = validate_basedir(args.base_dir)
    setup_logging(basedir, "vmware-metrics")

    config_file = os.path.join(basedir, "config.yaml")
    # Load config
    config = load_config(config_file)

    is_dry_run = args.dry_run or config.get("dry_run", False)
    logging.info("Starting VMWare metrics collector: dry_run=%s", is_dry_run)

    oci_config = config.get("oci")
    vconfig = config.get("vcenter")
    host = vconfig.get("host")

    ociClient = OCIClient(oci_config, vcenter_host=host)

    logging.info("Fetching entity OCID map from OCI Log Analytics API")
    try:
        entity_map = ociClient.get_entity_cache()
        logging.info(f"Fetched {len(entity_map)} entities from OCI LA")
    except Exception as e:
        logging.error(f"Failed to fetch entity mapping: {e}")
        return

    user = ociClient.get_secret(vconfig.get("user_secret_ocid"))
    password = ociClient.get_secret(vconfig.get("password_secret_ocid"))
    port = vconfig.get("port", "443")

    source = oci_config.get("metrics_source")

    vcenterClient = VCenterClient(host, port, user, password)

    logging.info("Collecting vCenter metrics")

    try:
        metrics_collected = vcenterClient.collect_metrics()
        #logging.info(f"Going to add synthetic metrics")
        #metrics_collected = augment_with_fake_metrics(metrics_collected, entity_map)
        #logging.info(f"Added synthetic metrics")
    except Exception as e:
        logging.error(f"Failed to collect metrics: {e}")
        return

    payload = generate_la_payload(metrics_collected, entity_map, source)

    if is_dry_run:
        # Save locally
        logs_dir = os.path.join(basedir, "logs")
        payload_file = os.path.join(logs_dir, "metrics_payload.json")
        with open(payload_file, "w") as f:
            json.dump(payload, f, indent=2)
        logging.info(f"Payload written to {payload_file}")

    # Upload to OCI LA if not dry-run
    if is_dry_run:
        logging.info("DRY run mode enabled. Skipping upload to OCI.")
    else:
        try:
            ociClient.upload_log_events_file(payload)
            logging.info("Successfully uploaded metrics to OCI Log Analytics")
        except Exception as e:
            logging.error(f"Failed to upload metrics: {e}")

if __name__ == "__main__":
    main()

