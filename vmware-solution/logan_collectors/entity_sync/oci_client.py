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
from constants import (
    CACHE_TTL_SECONDS,
    OCI_READ_RETRY_ATTEMPTS,
    OCI_READ_RETRY_INITIAL_DELAY_SECONDS,
    OCI_READ_RETRY_MAX_DELAY_SECONDS,
    VMWARE_ENTITY_TYPES,
)
from utils import get_solution_user_agent

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
        config["additional_user_agent"] = " ".join(
            filter(None, (config.get("additional_user_agent"), get_solution_user_agent()))
        )
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
        self.read_retry_attempts = params.get("read_retry_attempts", OCI_READ_RETRY_ATTEMPTS)
        if not isinstance(self.read_retry_attempts, int) or self.read_retry_attempts < 1:
            raise ValueError("oci.read_retry_attempts must be an integer greater than zero")
        self.sync_summary = {
            "entities_created": 0,
            "entities_existing": 0,
            "entities_would_create": 0,
            "entities_failed": 0,
            "associations_added": 0,
            "associations_existing": 0,
            "associations_removed": 0,
            "associations_would_add": 0,
            "associations_would_remove": 0,
            "associations_failed": 0,
            "associations_skipped": 0,
        }

    def _make_key(self, entity_type: str, entity_name: str) -> str:
        """Normalize cache key for an entity."""
        return f"{entity_type.strip().lower()}::{entity_name.strip().lower()}"

    @staticmethod
    def _is_retryable_read_error(error: ServiceError) -> bool:
        return getattr(error, "status", None) == 429 or 500 <= getattr(error, "status", 0) <= 599

    @staticmethod
    def _retry_after_seconds(error: ServiceError, fallback: int) -> int:
        headers = getattr(error, "headers", None) or {}
        retry_after = headers.get("retry-after") or headers.get("Retry-After")
        try:
            return max(0, int(retry_after)) if retry_after is not None else fallback
        except (TypeError, ValueError):
            return fallback

    def _read_with_retry(self, operation, description):
        """Run an OCI read, retrying only throttling and transient server errors."""
        for attempt in range(1, self.read_retry_attempts + 1):
            try:
                return operation()
            except ServiceError as error:
                if not self._is_retryable_read_error(error):
                    raise
                if attempt == self.read_retry_attempts:
                    logging.error(
                        "%s failed with HTTP %s after %d/%d attempts; aborting entity sync before changes are made.",
                        description, error.status, attempt, self.read_retry_attempts,
                    )
                    raise
                backoff = min(
                    OCI_READ_RETRY_INITIAL_DELAY_SECONDS * (2 ** (attempt - 1)),
                    OCI_READ_RETRY_MAX_DELAY_SECONDS,
                )
                delay = self._retry_after_seconds(error, backoff)
                logging.warning(
                    "%s returned HTTP %s (attempt %d/%d); retrying in %d seconds.",
                    description, error.status, attempt, self.read_retry_attempts, delay,
                )
                time.sleep(delay)

    def get_vcenter_entity_id(self):
        if not self.vcenter_entity_id:
            try:
                resp = self._read_with_retry(
                    lambda: self.la_client.list_log_analytics_entities(
                        namespace_name=self.namespace,
                        compartment_id=self.compartment,
                        name=self.vcenter_host,
                        entity_type_name=["VMWare vSphere vCenter"],
                        lifecycle_state="ACTIVE",
                    ),
                    "Fetching the vCenter entity from OCI Log Analytics",
                )

                if not hasattr(resp.data, "__iter__") and not hasattr(resp.data, "items"):
                    logging.warning("No entities returned from OCI LA")

                vcenter_entity = None
                for entity in getattr(resp.data, "items", []):
                    vcenter_entity = entity
                    break
                if not vcenter_entity:
                    logging.error("vCenter entity %s was not found in OCI Log Analytics", self.vcenter_host)
                    return None
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
        vcenter_entity_id = self.get_vcenter_entity_id()
        if not vcenter_entity_id:
            raise RuntimeError("Cannot refresh entity cache because the vCenter entity was not found")

        try:
            resp = self._read_with_retry(
                lambda: self.la_client.list_log_analytics_entity_topology(
                    namespace_name=self.namespace,
                    log_analytics_entity_id=vcenter_entity_id,
                    lifecycle_state="ACTIVE",
                ),
                "Refreshing the OCI Log Analytics entity topology",
            )

            entity_cache = {}
            association_cache = {}

            for item in getattr(resp.data, "items", []):
                entities = getattr(item.nodes, "items", [])
                for entity in entities:
                    if getattr(entity, "lifecycle_state", None) != "ACTIVE":
                        logging.debug(
                            "Ignoring non-ACTIVE entity state=%s name=%s ocid=%s",
                            getattr(entity, "lifecycle_state", None), getattr(entity, "name", None),
                            getattr(entity, "id", None),
                        )
                        continue
                    etype = getattr(entity, "entity_type_name", None)
                    if etype in VMWARE_ENTITY_TYPES:
                        key = self._make_key(etype, entity.name)
                        entity_cache[key] = entity.id
                        logging.debug("Caching entity key=%s, ocid=%s", key, entity.id)

                all_assocs = getattr(item.links, "items", [])
                for assoc in all_assocs:
                    if assoc.source_entity_id and assoc.destination_entity_id:
                        if assoc.source_entity_id not in association_cache:
                            association_cache[assoc.source_entity_id] = set()
                        association_cache[assoc.source_entity_id].add(assoc.destination_entity_id)

            self.entity_cache = entity_cache
            self.association_cache = association_cache
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
            logging.error("Invalid entity payload (missing 'type' or 'name'): %s", entity)
            self.sync_summary["entities_failed"] += 1
            return None

        etype = entity["type"]
        ename = entity["name"]

        self.refresh_caches()

        key = self._make_key(entity["type"], entity["name"])
        if key in self.entity_cache:
            self.sync_summary["entities_existing"] += 1
            logging.info("Entity already exists in OCI LA; no update required: %s", key)
            return self.entity_cache[key]

        if self.dry_run:
            logging.info("[dry-run] Would create entity: %s", key)
            self.entity_cache[key] = f"mock_ocid::{key}"
            self.sync_summary["entities_would_create"] += 1
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
            self.sync_summary["entities_created"] += 1
            logging.info("Created entity: %s -> %s", key, ocid)
            return ocid
        except ServiceError as e:
            logging.error("ServiceError creating entity %s: %s", key, e)
            self.sync_summary["entities_failed"] += 1
        except Exception as e:
            logging.error("Unexpected error creating entity %s: %s", key, e)
            self.sync_summary["entities_failed"] += 1

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
                self.sync_summary["associations_skipped"] += 1
                continue

            # Resolve child and parent OCIDs from cache
            child_ocid = self.entity_cache.get(self._make_key(entity["type"], entity["name"]))
            parent_ocid = self.entity_cache.get(self._make_key(parent_def["type"], parent_def["name"]))

            # Skip if parent or child not in cache (stale association)
            if not parent_ocid or not child_ocid:
                self.sync_summary["associations_failed"] += 1
                logging.warning("Cannot reconcile association because an entity is missing from OCI cache: %s", entity)
                continue

            desired_map.setdefault(parent_ocid, set()).add(child_ocid)

        # Existing associations from cache
        existing_map = self.association_cache

        # Reconcile each parent
        for parent_ocid, desired_children in desired_map.items():
            existing_children = existing_map.get(parent_ocid, set())

            # Add new associations
            to_add = desired_children - existing_children
            existing_children_for_parent = desired_children & existing_children
            self.sync_summary["associations_existing"] += len(existing_children_for_parent)
            for child_ocid in existing_children_for_parent:
                logging.info("Association already exists in OCI LA; no update required: %s -> %s",
                             parent_ocid, child_ocid)
            if to_add:
                if self.dry_run:
                    logging.info("[dry-run] Would add associations %s -> %s", parent_ocid, to_add)
                    self.sync_summary["associations_would_add"] += len(to_add)
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
                        self.sync_summary["associations_added"] += len(to_add)
                        logging.info("Added associations %s -> %s", parent_ocid, to_add)
                        existing_map.setdefault(parent_ocid, set()).update(to_add)
                    except ServiceError as e:
                        logging.error("Failed to add associations %s -> %s: %s", parent_ocid, to_add, e)
                        self.sync_summary["associations_failed"] += len(to_add)
                    except Exception as e:
                        logging.error("Unexpected error adding associations %s -> %s: %s", parent_ocid, to_add, e)
                        self.sync_summary["associations_failed"] += len(to_add)

            # Remove stale associations (only those not in desired set)
            to_remove = existing_children - desired_children
            if to_remove:
                if self.dry_run:
                    logging.info("[dry-run] Would remove associations %s -> %s", parent_ocid, to_remove)
                    self.sync_summary["associations_would_remove"] += len(to_remove)
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
                        self.sync_summary["associations_removed"] += len(to_remove)
                        logging.info("Removed associations %s -> %s", parent_ocid, to_remove)
                        existing_map[parent_ocid] -= to_remove
                        if not existing_map[parent_ocid]:
                            del existing_map[parent_ocid]
                    except ServiceError as e:
                        logging.error("Failed to remove associations %s -> %s: %s", parent_ocid, to_remove, e)
                        self.sync_summary["associations_failed"] += len(to_remove)
                    except Exception as e:
                        logging.error("Unexpected error removing associations %s -> %s: %s", parent_ocid, to_remove, e)
                        self.sync_summary["associations_failed"] += len(to_remove)

        # Handle parents that no longer exist in discovered_entities
        stale_parents = set(existing_map.keys()) - set(desired_map.keys())
        for parent_ocid in stale_parents:
            to_remove = existing_map[parent_ocid]
            if not to_remove:
                continue
            if self.dry_run:
                logging.info("[dry-run] Would remove associations for stale parent %s -> %s", parent_ocid, to_remove)
                self.sync_summary["associations_would_remove"] += len(to_remove)
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
                    self.sync_summary["associations_removed"] += len(to_remove)
                    logging.info("Removed associations for stale parent %s -> %s", parent_ocid, to_remove)
                    del existing_map[parent_ocid]
                except ServiceError as e:
                    logging.error("Failed to remove associations for stale parent %s: %s", parent_ocid, e)
                    self.sync_summary["associations_failed"] += len(to_remove)
                except Exception as e:
                    logging.error("Unexpected error removing associations for stale parent %s: %s", parent_ocid, e)
                    self.sync_summary["associations_failed"] += len(to_remove)

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
