import argparse
import logging
import os
import yaml
from oci_client import OCIClientWrapper
from vcenter_client import VCenterClient
from utils import validate_basedir, setup_logging, load_config

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-dir", required=True, help="Base directory containing config.yaml, logs/, and state/")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    basedir = validate_basedir(args.base_dir)
    setup_logging(basedir, "vmware-entity-sync")


    config_file = os.path.join(basedir, "config.yaml")
    # Load config
    config = load_config(config_file)

    is_dry_run = args.dry_run or config.get("dry_run", False)
    logging.info("Starting VMWare Entity Sync: dry_run=%s", is_dry_run)

    # Read parameters
    oconfig = config["oci"]
    vconfig = config["vcenter"]
    host = vconfig["host"]

    logging.info("Creating OCI Client")
    client = OCIClientWrapper(oconfig, host, dry_run=is_dry_run)

    user = client.get_secret(vconfig.get("user_secret_ocid"))
    password = client.get_secret(vconfig.get("password_secret_ocid"))

    logging.info("load Caches")
    client.refresh_caches()

    vc = VCenterClient(host, user, password, dry_run=is_dry_run)
    vc.connect()
    entities = vc.get_entities()
    vc.disconnect()

    for entity in entities:
        ocid = client.get_or_create_entity(entity)

    logging.info("Reconcile Entity Associations")
    client.reconcile_all_entity_associations(entities)
    print("Entity Sync Completed")

if __name__ == "__main__":

    main()

