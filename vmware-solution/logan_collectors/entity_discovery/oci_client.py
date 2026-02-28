#
# Copyright (c) 2026 Oracle, Inc.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
import os
import time
import logging
from typing import Dict, Optional
import base64

import oci
from oci.log_analytics import LogAnalyticsClient
from oci.exceptions import ServiceError
from oci.pagination import list_call_get_all_results

try:
    from oci.log_analytics.models import CreateLogAnalyticsEntityDetails
except ImportError:
    from oci.log_analytics.models import CreateLogAnalyticsEntity as CreateLogAnalyticsEntityDetails

try:
    from oci.log_analytics.models import AddEntityAssociationDetails
except ImportError:
    AddEntityAssociationDetails = None

from constants import VMWARE_ENTITY_TYPES, CACHE_TTL_SECONDS


def _make_key(entity_type: str, entity_name: str) -> str:
    """Normalize cache key for an entity."""
    return f"{entity_type.strip().lower()}::{entity_name.strip().lower()}"


class OCIClientWrapper:
    def __init__(self, params, vcenter_host, dry_run: bool = False):
        self.logger = logging.getLogger(__name__)
        self.dry_run = dry_run
        self.vcenter_host = vcenter_host
        self.vcenter_entity_id = None

        self.namespace = params["log_analytics_namespace"]
        self.compartment = params["compartment_id"]
        if not self.namespace or not self.compartment:
            raise RuntimeError("Missing required env vars: oci_namespace and compartment_id")

        #if not self.dry_run:
        cfg_path = params.get("config_file", "~/.oci/config")
        config = oci.config.from_file(file_location=os.path.expanduser(cfg_path))
        self.la_client = None
        la_endpoint = params.get("logan_endpoint")
        if la_endpoint:
            logging.info("Creating LA client using endpoint=%s", la_endpoint)
            self.la_client = LogAnalyticsClient(config,service_endpoint=la_endpoint)
            logging.info("LA Client is using endpoint=%s", self.la_client.base_client.endpoint)
        else:
            self.la_client = LogAnalyticsClient(config)
        
        self.vault_client =  oci.secrets.SecretsClient(config)

        self.entity_cache: Dict[str, str] = {}  # VMware entity cache
        self.cache_timestamp: float = 0.0
        self.cache_ttl: int = 300  # 5 minutes TTL

    # ---------------- Cache ----------------
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
                if vcenter_entity:
                    self.vcenter_entity_id = vcenter_entity.id
                else:
                    logging.info("VCenter Entity Not Found")
            except ServiceError as e:
                logging.error("ServiceError fetching vCenter entity: %s", e)
                raise e
            except Exception as e:
                logging.error("Unexpected error getting vCenter entity : %s", e)
                raise e

        return self.vcenter_entity_id


    def refresh_entity_cache(self):
        now = time.time()
        if now - self.cache_timestamp < CACHE_TTL_SECONDS:
            return

        logging.info("Refreshing caches from OCI")
        self.entity_cache = {}
        vcenter_entity_id = self.get_vcenter_entity_id()

        if vcenter_entity_id is None:
            return

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
                        key = _make_key(etype, entity.name)
                        self.entity_cache[key] = entity.id
                        logging.debug("Caching entity key=%s, ocid=%s", key, entity.id)

            self.cache_timestamp = now
            logging.info("Cached %d VMware entities", len(self.entity_cache))
        except ServiceError as e:
            logging.error("ServiceError refreshing entity cache: %s", e)
            raise e
        except Exception as e:
            logging.error("Unexpected error refreshing entity cache: %s", e)
            raise e

    # ---------------- Entities ----------------
    def get_or_create_entity(self, entity: dict) -> Optional[str]:
        if "type" not in entity or "name" not in entity:
            self.logger.error("Invalid entity payload (missing 'type' or 'name'): %s", entity)
            return None

        etype = entity["type"]
        ename = entity["name"]

        if etype not in VMWARE_ENTITY_TYPES:
            self.logger.info("Skipping non-VMware entity type: %s (%s)", etype, ename)
            return None

        self.refresh_entity_cache()
        key = _make_key(etype, ename)
        if key in self.entity_cache:
            self.logger.debug("Found entity in cache: %s -> %s", key, self.entity_cache[key])
            return self.entity_cache[key]

        if self.dry_run:
            fake_ocid = f"ocid1.mockentity.oc1..{abs(hash(key)) & 0xFFFFFFFF:X}"
            self.entity_cache[key] = fake_ocid
            self.logger.info("[DRY-RUN] Would create entity: %s -> %s", key, fake_ocid)
            return fake_ocid

        self.logger.debug("Creating entity type: %s -> name:%s", etype, ename)
        try:
            properties= {"vcenter": self.vcenter_host}
            details = CreateLogAnalyticsEntityDetails(
                name=ename,
                entity_type_name=etype,
                compartment_id=self.compartment,
                management_agent_id=None,
                properties=properties,
            )
            try:
                resp = self.la_client.create_log_analytics_entity(
                    namespace_name=self.namespace,
                    create_log_analytics_entity_details=details,
                    retry_strategy=oci.retry.DEFAULT_RETRY_STRATEGY,
                )
            except TypeError:
                resp = self.la_client.create_log_analytics_entity(
                    namespace_name=self.namespace,
                    create_log_analytics_entity_details=details,
                )

            ocid = resp.data.id
            self.entity_cache[key] = ocid
            self.cache_timestamp = time.time()  # update cache timestamp immediately
            self.logger.info("Created entity: %s -> %s", key, ocid)
            return ocid

        except ServiceError as se:
            if getattr(se, "status", None) == 409:
                self.logger.warning("Entity already exists (409): %s; refreshing cache", key)
                self.refresh_entity_cache(force=True)
                return self.entity_cache.get(key)
            self.logger.error("ServiceError creating entity %s: %s", key, se, exc_info=True)
            return None
        except Exception as e:
            self.logger.error("Unexpected error creating entity %s: %s", key, e, exc_info=True)
            return None

    # ---------------- Associations ----------------
    def create_entity_assoc(self, entity: dict) -> None:
        if "parent" not in entity or not entity["parent"]:
            self.logger.debug("Entity has no parent, skipping association: %s::%s",
                              entity.get("type"), entity.get("name"))
            return

        parent_info = entity["parent"]
        child_key = _make_key(entity["type"], entity["name"])
        parent_key = _make_key(parent_info["type"], parent_info["name"])

        self.refresh_entity_cache()

        parent_id = self.entity_cache.get(parent_key)
        child_id = self.entity_cache.get(child_key)

        if not parent_id or not child_id:
            self.logger.warning(
                "Cannot create association: missing OCIDs (parent=%s, child=%s). "
                "Ensure both entities were created/cached.", parent_key, child_key
            )
            return

        if self.dry_run:
            self.logger.info("[DRY-RUN] Would associate %s -> %s (%s -> %s)",
                             parent_key, child_key, parent_id, child_id)
            return

        if AddEntityAssociationDetails is None:
            self.logger.warning("Entity associations not supported by this OCI SDK version; skipping.")
            return

        try:
            details = AddEntityAssociationDetails(association_entities=[child_id])
            self.la_client.add_entity_association(
                namespace_name=self.namespace,
                log_analytics_entity_id=parent_id,
                add_entity_association_details=details,
                retry_strategy=oci.retry.DEFAULT_RETRY_STRATEGY,
            )
            self.logger.info("Created association: %s -> %s", parent_key, child_key)

        except oci.exceptions.ServiceError as se:
            if getattr(se, "status", None) == 409:
                self.logger.info("Association already exists (409): %s -> %s", parent_key, child_key)
                return
            self.logger.error("ServiceError creating association %s -> %s: %s",
                              parent_key, child_key, se, exc_info=True)
        except Exception as e:
            self.logger.error("Unexpected error creating association %s -> %s: %s",
                              parent_key, child_key, e, exc_info=True)

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
