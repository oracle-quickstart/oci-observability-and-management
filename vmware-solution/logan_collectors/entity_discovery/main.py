import os
import sys
import json
import logging
import argparse
import yaml
from oci_client import OCIClientWrapper
from vcenter_client import VCenterClient
from utils import validate_basedir, setup_logging, load_config

def main():
    parser = argparse.ArgumentParser(description="vCenter Entity Discovery")
    parser.add_argument("--base-dir", required=True, help="Base directory containing config.yaml, logs/, and state/")
    parser.add_argument("--dry-run", action="store_true", help="Do not write to OCI")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose logging")
    args = parser.parse_args()

    basedir = validate_basedir(args.base_dir)
    setup_logging(basedir, "vmware-entity-discovery")

    logging.info("Starting VMware Entity discovery...")

    config_file = os.path.join(basedir, "config.yaml")
    # Load config
    config = load_config(config_file)

    is_dry_run = args.dry_run or config.get("dry_run", False)
    logging.info("Starting entity discovery: dry_run=%s", is_dry_run)

    # Read parameters

    oconfig = config["oci"]
    vconfig = config["vcenter"]
    host = vconfig["host"]
    # user = vcenter_config["user"]
    # password = vcenter_config["password"]

    logging.info("Creating OCI Client")
    client = OCIClientWrapper(oconfig, host, dry_run=is_dry_run)

    user = client.get_secret(vconfig.get("user_secret_ocid"))
    password = client.get_secret(vconfig.get("password_secret_ocid"))

    if not host or not user or not password:
        logger.error("Missing vCenter config parameters (VCENTER_HOST, VCENTER_USER, VCENTER_PASSWORD)")
        sys.exit(1)

    logging.info("load Cache")
    client.refresh_entity_cache()

    vc = VCenterClient(host, user, password, dry_run=args.dry_run)
    vc.connect()
    entities = vc.get_entities()
    vc.disconnect()

    if not entities:
        logger.warning("No entities retrieved.")
        return

    """
    Write fetched/discovered entities into a JSON file for debugging and later analysis.
    """
    logs_dir = os.path.join(basedir, "logs")
    entities_file = os.path.join(logs_dir, "discovered_entities.json")
    try:
        with open(entities_file, "w", encoding="utf-8") as f:
            json.dump(entities, f, indent=2, ensure_ascii=False)
        logging.info("Wrote %d entities to %s", len(entities), os.path.abspath(entities_file))
    except Exception as e:
        logging.error("Failed to write entities to file %s: %s", filename, e)

    for entity in entities:
        ocid = client.get_or_create_entity(entity)

    logging.info("Processing Entity Associations")

    # Now process associations
    for entity in entities:
        client.create_entity_assoc(entity)

if __name__ == "__main__":
    main()

