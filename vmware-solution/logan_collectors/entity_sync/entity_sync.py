#
# Copyright (c) 2026 Oracle, Inc.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
import argparse
import logging
import os
import yaml
from oci_client import OCIClientWrapper
from vcenter_client import VCenterClient
from utils import validate_basedir, get_config_file, setup_logging, load_config

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-dir", required=True, help="Base directory containing config.yaml, logs/, and state/")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    basedir = validate_basedir(args.base_dir)
    setup_logging(basedir, "vmware-entity-sync")


    config_file = get_config_file(basedir)
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

    logging.info("Loading OCI entity and association caches")
    try:
        client.refresh_caches()
    except Exception:
        logging.exception(
            "Unable to load OCI Log Analytics state; aborting entity sync before creating entities or associations."
        )
        return 1

    vc = VCenterClient(host, user, password, dry_run=is_dry_run)
    vc.connect()
    entities = vc.get_entities()
    vc.disconnect()

    try:
        for entity in entities:
            client.get_or_create_entity(entity)

        logging.info("Reconcile Entity Associations")
        client.reconcile_all_entity_associations(entities)
    except Exception:
        logging.exception("Entity sync failed; stopping without processing additional entities or associations.")
        return 1

    summary = client.sync_summary
    logging.info(
        "entity_sync outcome: entities(created=%d, existing=%d, would_create=%d, failed=%d); "
        "associations(added=%d, existing=%d, removed=%d, would_add=%d, would_remove=%d, skipped=%d, failed=%d)",
        summary["entities_created"], summary["entities_existing"], summary["entities_would_create"],
        summary["entities_failed"], summary["associations_added"], summary["associations_existing"],
        summary["associations_removed"], summary["associations_would_add"],
        summary["associations_would_remove"], summary["associations_skipped"],
        summary["associations_failed"],
    )
    if all(summary[key] == 0 for key in (
            "entities_created", "entities_would_create", "entities_failed",
            "associations_added", "associations_removed", "associations_would_add",
            "associations_would_remove", "associations_failed",
    )):
        logging.info("entity_sync completed: OCI Log Analytics is already up to date; no updates required.")
    print("Entity Sync Run Completed")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
