#
# Copyright (c) 2026 Oracle, Inc.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
import oci
import os
import io
import json
import logging
import time
import tempfile
import gzip
import base64
from typing import List, Dict
from constants import SUPPORTED_ENTITY_TYPES, VC_TO_OCI_ENTITY_TYPE
from oci.log_analytics import LogAnalyticsClient
from oci.exceptions import ServiceError, RequestException
    
logger = logging.getLogger("oci_client")
logger.setLevel(logging.DEBUG)
#
# -------- Entity Cache Logic --------
#
def normalize(text: str) -> str:
    """Normalize strings for consistent cache keys."""
    return text.strip().lower() if text else ""

def normalize_entity_type(s: str) -> str:
    if not s:
        return ""
    return s.strip().strip("'").strip('"')

def make_entity_key(entity_type: str, entity_name: str) -> str:
    """Normalize key to match LA keys: lower case, strip spaces"""
    return f"{entity_type.strip().lower()}::{entity_name.strip().lower()}"

def normalize_entity_key(name: str, entity_type: str) -> str:
    if not name:
        name = "unknown"
    return f"{entity_type.strip().lower()}::{name.strip().lower().replace(' ', '_')}"

    
def find_matching_ocid(entity_map: dict, vcenter_type: str, entity_name: str) -> str:
    """
    Map vCenter entity type to OCI type, normalize key, and return OCID.
    Returns 'UNKNOWN' if no mapping found.
    """
    oci_type = VC_TO_OCI_ENTITY_TYPE.get(vcenter_type, vcenter_type)
    key = make_entity_key(oci_type, entity_name)
    if key in entity_map:
        return entity_map[key]
    
    logger.info(f"No OCID mapping found for key=%s", key)
    return None

class OCIClient:
    
    def __init__(self, params, vcenter_host, dry_run=False):
        self.dry_run = dry_run
        self.namespace = params["log_analytics_namespace"]
        self.compartment = params["compartment_id"]
        self.log_group_id = params["log_group_id"]
        self.vcenter_host = vcenter_host,
        if not self.namespace or not self.compartment:
            raise RuntimeError("Missing required env vars: oci_namespace and compartment_id")

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

        self.entity_cache = {}  # key -> entity OCID
        self.cache_timestamp = 0
        self.vcenter_entity_id = None

    # -------------------------------------------------------------
    # Fetch secret from OCI Vault
    # -------------------------------------------------------------
    def get_secret(self, secret_id: str) -> str:
        try:
            resp = self.vault_client.get_secret_bundle(secret_id)
            base64_secret = resp.data.secret_bundle_content.content
            return base64.b64decode(base64_secret).decode("utf-8")
        except Exception as e:
            logger.error("Failed to fetch secret for %s: %s", secret_id, e)
            raise 

    def get_vcenter_entity_id(self):
        if not self.vcenter_entity_id:
            try:
                # Get entity id of vcenter entity first
                resp = self.la_client.list_log_analytics_entities(
                    namespace_name=self.namespace,
                    compartment_id = self.compartment,
                    name=self.vcenter_host,
                    entity_type_name=["VMWare vSphere vCenter"],
                    lifecycle_state="ACTIVE")

                if not hasattr(resp.data, "__iter__") and not hasattr(resp.data, "items"):
                    logger.warning("No vCenter entity returned from OCI LA")

                vcenter_entity = None
                for entity in getattr(resp.data, "items", []):
                    vcenter_entity = entity

                if vcenter_entity:
                    self.vcenter_entity_id = vcenter_entity.id
                    logger.warning("Retrieved vCenter entity from OCI LA %s",self.vcenter_entity_id)

            except oci.exceptions.ServiceError as se:
                logger.error(f"OCI ServiceError while fetching entities: {se.code} - {se.message}")
                raise
            except oci.exceptions.ClientError as ce:
                logger.error(f"OCI ClientError while fetching entities: {ce.message}")
                raise
            except Exception as e:
                logger.error(f"Unexpected error fetching entities: {e}")
                raise

        return self.vcenter_entity_id
    

    #
    # Build Entity Map
    #
    def get_entity_cache(self):
        """
        Fetch all VMware-related entities from OCI Log Analytics and return a normalized map.
        Returns: {normalized_key: entity_ocid}
        """
        mapping = {}

        vcenter_entity_ocid = self.get_vcenter_entity_id()
        if not vcenter_entity_ocid:
            logger.warning("No vCenter entity found from OCI LA")
            return mapping

        page = None
        try:
            while True:
                resp = self.la_client.list_entity_associations(
                    namespace_name=self.namespace,
                    log_analytics_entity_id=vcenter_entity_ocid,
                    direct_or_all_associations="ALL",
                    limit=200,
                    page=page
                )
    
                if not hasattr(resp.data, "__iter__") and not hasattr(resp.data, "items"):
                    logger.warning("No entities returned from OCI LA")
                    break
    
                for entity in getattr(resp.data, "items", []):
                    if entity.entity_type_name in SUPPORTED_ENTITY_TYPES:
                        key = make_entity_key(entity.entity_type_name, entity.name)
                        mapping[key] = entity.id
                        logger.info("Caching entity state=%s key:%s: ocid=%s",entity.lifecycle_state, key, entity.id)
    
                # Handle pagination
                page = resp.headers.get("opc-next-page") if resp.headers else None
                if not page:
                    break
    
        except oci.exceptions.ServiceError as se:
            logger.error(f"OCI ServiceError while fetching entities: {se.code} - {se.message}")
        except oci.exceptions.ClientError as ce:
            logger.error(f"OCI ClientError while fetching entities: {ce.message}")
        except Exception as e:
            logger.error(f"Unexpected error fetching entities: {e}")
    
        logger.info(f"Fetched {len(mapping)} VMware entities from OCI LA")

        self.entity_cache = mapping
        return mapping
    
    #
    # -------- Upload Logic --------
    #
    def upload_log_events_file(self, payload):
        """
        Upload log events file to OCI Log Analytics using UploadLogEventsFile API.
        Saves payload to a temp file, then uploads it as binary.
        """
        try:
    
            #1. Write payload to a temp file
            with tempfile.NamedTemporaryFile(mode="w", delete=False, suffix=".json") as tmpfile:
                json.dump(payload, tmpfile)
                tmpfile.flush()
                tmp_path = tmpfile.name
                logger.debug(f"[Upload] Payload written to temporary file {tmp_path}")

            # 2. Read the file back in binary mode
            with open(tmp_path, "rb") as f:
                file_bytes = f.read()

            response = self.la_client.upload_log_events_file(
                namespace_name=self.namespace,
                upload_log_events_file_details=file_bytes,
                log_group_id=self.log_group_id,
                content_type="application/octet-stream",
                payload_type="JSON"
            )

            logger.info(f"Upload response: {response.status}, opc-request-id={response.headers.get('opc-request-id')}")
            print(f"Upload response: {response.status}, opc-request-id={response.headers.get('opc-request-id')}")
            return response
        except ServiceError as e:
            logger.error(f"[Upload] ServiceError: {e.status} {e.code} - {e.message}")
            return None
        except Exception as e:
            logger.error(f"Failed to upload log events file: {e}", exc_info=True)
            raise

    def find_entity(self, entity_type, name):
        key = make_entity_key(entity_type, name)
        if key in self.entity_cache:
            return self.entity_cache.get(key)

        logger.info(f"No OCID mapping found for key=%s:", key)
        return None
