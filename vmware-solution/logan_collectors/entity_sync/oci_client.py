#
# Copyright (c) 2026 Oracle, Inc.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
import logging
import os
import time
import oci
import base64
from oci.log_analytics import LogAnalyticsClient
from oci.log_analytics.models import AddEntityAssociationDetails, RemoveEntityAssociationsDetails
try:
    from oci.log_analytics.models import CreateLogAnalyticsEntityDetails
except ImportError:
    from oci.log_analytics.models import CreateLogAnalyticsEntity as CreateLogAnalyticsEntityDetails
from oci.exceptions import ServiceError
from oci.pagination import list_call_get_all_results
from constants import VMWARE_ENTITY_TYPES, CACHE_TTL_SECONDS

class OCIClientWrapper:
    def __init__(self, params, vcenter_host, dry_run=False):
        self.dry_run = dry_run
        self.vcenter_host = vcenter_host
        self.namespace = params["log_analytics_namespace"]
        self.compartment = params["compartment_id"]
        if not self.namespace or not self.compartment:
            raise RuntimeError("Missing required env vars: oci_namespace and compartment_id")

        cfg_path = params.get("config_file", "~/.oci/config")
        config = oci.config.from_file(file_location=os.path.expanduser(cfg_path))
        la_endpoint = params.get("logan_endpoint")
        if la_endpoint:
            logging.info("Creating LA client using endpoint=%s", la_endpoint)
            self.la_client = LogAnalyticsClient(config,service_endpoint=la_endpoint)
            logging.info("LA Client is using endpoint=%s", self.la_client.base_client.endpoint)
        else:
            self.la_client = LogAnalyticsClient(config)
        
        self.vault_client =  oci.secrets.SecretsClient(config)

        self.entity_cache = {}  # key -> entity OCID
        self.association_cache = {}  # parent OCID -> set(child OCID)
        self.cache_timestamp = 0
        self.vcenter_entity_id = None

    def _make_key(self, entity_type: str, entity_name: str) -> str:
        """Normalize cache key for an entity."""
        return f"{entity_type.strip().lower()}::{entity_name.strip().lower()}"

    def get_vcenter_entity_id(self):
        if not self.vcenter_entity_id:
            try:
                resp = self.la_client.list_log_analytics_entities(
                    namespace_name=self.namespace,
                    compartment_id = self.compartment,
                    name=self.vcenter_host,
                    entity_type_name=["VMWare vSphere vCenter"],
                    lifecycle_state="ACTIVE")

                if not hasattr(resp.data, "__iter__") and not hasattr(resp.data, "items"):
                    logging.warning("No entities returned from OCI LA")

                vcenter_entity = None
                for entity in getattr(resp.data, "items", []):
                    vcenter_entity = entity
                    break
                self.vcenter_entity_id = vcenter_entity.id
            except ServiceError as e:
                logging.error("ServiceError fetching vCenter entity: %s", e)
                raise e
            except Exception as e:
                logging.error("Unexpected error getting vCenter entity : %s", e)
                raise e

        return self.vcenter_entity_id


    def refresh_caches(self):
        now = time.time()
        if now - self.cache_timestamp < CACHE_TTL_SECONDS:
            return

        logging.info("Refreshing caches from OCI")
        self.entity_cache = {}
        self.association_cache = {}
        vcenter_entity_id = self.get_vcenter_entity_id()

        try:
            resp = self.la_client.list_log_analytics_entity_topology(
                namespace_name=self.namespace,
                log_analytics_entity_id=vcenter_entity_id,
                lifecycle_state="ACTIVE")

            for item in getattr(resp.data, "items", []):
                entities = getattr(item.nodes, "items", [])
                for entity in entities:
                    etype = getattr(entity, "entity_type_name", None)
                    if etype in VMWARE_ENTITY_TYPES:
                        key = self._make_key(etype, entity.name)
                        self.entity_cache[key] = entity.id
                        logging.debug("Caching entity key=%s, ocid=%s", key, entity.id)

                all_assocs = getattr(item.links, "items", [])
                for assoc in all_assocs:
                    if assoc.source_entity_id and assoc.destination_entity_id:
                        if not assoc.source_entity_id in self.association_cache:
                            self.association_cache[assoc.source_entity_id] = set()
                        self.association_cache[assoc.source_entity_id].add(assoc.destination_entity_id)

            self.cache_timestamp = now
            logging.info("Cached %d VMware entities", len(self.entity_cache))
        except ServiceError as e:
            logging.error("ServiceError refreshing entity cache: %s", e)
            raise e
        except Exception as e:
            logging.error("Unexpected error refreshing entity cache: %s", e)
            raise e

    def get_or_create_entity(self, entity):
        if "type" not in entity or "name" not in entity:
            self.logger.error("Invalid entity payload (missing 'type' or 'name'): %s", entity)
            return None

        etype = entity["type"]
        ename = entity["name"]

        self.refresh_caches()

        key = self._make_key(entity["type"], entity["name"])
        if key in self.entity_cache:
            return self.entity_cache[key]

        if self.dry_run:
            logging.info("[dry-run] Would create entity: %s", key)
            self.entity_cache[key] = f"mock_ocid::{key}"
            return self.entity_cache[key]
        try:
            properties= {"vcenter": self.vcenter_host}
            details = CreateLogAnalyticsEntityDetails(
                name=ename,
                entity_type_name=etype,
                compartment_id=self.compartment,
                management_agent_id=None,
                properties=properties,
            )
            resp = self.la_client.create_log_analytics_entity(
                namespace_name=self.namespace,
                create_log_analytics_entity_details=details
            )
            ocid = resp.data.id
            self.entity_cache[key] = ocid
            logging.info("Created entity: %s -> %s", key, ocid)
            return ocid
        except ServiceError as e:
            logging.error("ServiceError creating entity %s: %s", key, e)
        except Exception as e:
            logging.error("Unexpected error creating entity %s: %s", key, e)

    def reconcile_all_entity_associations(self, discovered_entities):
        """
        Reconcile entity associations in OCI with discovered entities.

        Args:
            discovered_entities (list[dict]): List of discovered entity definitions.
                                              Each entity may include a "parent" section.
        """
        # Build desired mapping: parent_ocid -> set(child_ocids)
        desired_map = {}
        for entity in discovered_entities:
            parent_def = entity.get("parent")
            if not parent_def:
                continue

            # Resolve child and parent OCIDs from cache
            child_ocid = self.entity_cache.get(self._make_key(entity["type"], entity["name"]))
            parent_ocid = self.entity_cache.get(self._make_key(parent_def["type"], parent_def["name"]))

            # Skip if parent or child not in cache (stale association)
            if not parent_ocid or not child_ocid:
                continue

            desired_map.setdefault(parent_ocid, set()).add(child_ocid)

        # Existing associations from cache
        existing_map = self.association_cache

        # Reconcile each parent
        for parent_ocid, desired_children in desired_map.items():
            existing_children = existing_map.get(parent_ocid, set())

            # Add new associations
            to_add = desired_children - existing_children
            if to_add:
                if self.dry_run:
                    logging.info("[dry-run] Would add associations %s -> %s", parent_ocid, to_add)
                else:
                    try:
                        details = oci.log_analytics.models.AddEntityAssociationDetails(
                            association_entities=list(to_add)
                        )
                        self.la_client.add_entity_association(
                            namespace_name=self.namespace,
                            log_analytics_entity_id=parent_ocid,
                            add_entity_association_details=details
                        )
                        logging.info("Added associations %s -> %s", parent_ocid, to_add)
                        existing_map.setdefault(parent_ocid, set()).update(to_add)
                    except ServiceError as e:
                        logging.error("Failed to add associations %s -> %s: %s", parent_ocid, to_add, e)
                    except Exception as e:
                        logging.error("Unexpected error adding associations %s -> %s: %s", parent_ocid, to_add, e)

            # Remove stale associations (only those not in desired set)
            to_remove = existing_children - desired_children
            if to_remove:
                if self.dry_run:
                    logging.info("[dry-run] Would remove associations %s -> %s", parent_ocid, to_remove)
                else:
                    try:
                        details = oci.log_analytics.models.RemoveEntityAssociationsDetails(
                            association_entities=list(to_remove)
                        )
                        self.la_client.remove_entity_associations(
                            namespace_name=self.namespace,
                            log_analytics_entity_id=parent_ocid,
                            remove_entity_associations_details=details
                        )
                        logging.info("Removed associations %s -> %s", parent_ocid, to_remove)
                        existing_map[parent_ocid] -= to_remove
                        if not existing_map[parent_ocid]:
                            del existing_map[parent_ocid]
                    except ServiceError as e:
                        logging.error("Failed to remove associations %s -> %s: %s", parent_ocid, to_remove, e)
                    except Exception as e:
                        logging.error("Unexpected error removing associations %s -> %s: %s", parent_ocid, to_remove, e)

        # Handle parents that no longer exist in discovered_entities
        stale_parents = set(existing_map.keys()) - set(desired_map.keys())
        for parent_ocid in stale_parents:
            to_remove = existing_map[parent_ocid]
            if not to_remove:
                continue
            if self.dry_run:
                logging.info("[dry-run] Would remove associations for stale parent %s -> %s", parent_ocid, to_remove)
            else:
                try:
                    details = oci.log_analytics.models.RemoveEntityAssociationsDetails(
                        association_entities=list(to_remove)
                    )
                    self.la_client.remove_entity_associations(
                        namespace_name=self.namespace,
                        log_analytics_entity_id=parent_ocid,
                        remove_entity_associations_details=details
                    )
                    logging.info("Removed associations for stale parent %s -> %s", parent_ocid, to_remove)
                    del existing_map[parent_ocid]
                except ServiceError as e:
                    logging.error("Failed to remove associations for stale parent %s: %s", parent_ocid, e)
                except Exception as e:
                    logging.error("Unexpected error removing associations for stale parent %s: %s", parent_ocid, e)

        # Update cache
        self.association_cache = existing_map

    # -------------------------------------------------------------
    # Fetch secret from OCI Vault
    # -------------------------------------------------------------
    def get_secret(self, secret_id: str) -> str:
        try:
            resp = self.vault_client.get_secret_bundle(secret_id)
            base64_secret = resp.data.secret_bundle_content.content
            return base64.b64decode(base64_secret).decode("utf-8")
        except Exception as e:
            logging.error("Failed to fetch secret for %s: %s", secret_id, e)
            raise
