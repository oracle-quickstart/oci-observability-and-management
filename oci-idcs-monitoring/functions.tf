## Copyright (c) 2021, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_functions_application" "IdcsAuditLogApp" {
  compartment_id = var.compartment_ocid
  display_name   = "IdcsAuditLogApp-${random_id.tag.hex}"
  subnet_ids     = [var.create_network ? module.setup-network[0].fnsubnet_ocid : var.subnet_ocid]
  #defined_tags = { "${oci_identity_tag_namespace.IDCSAuditLogTagNamespace.name}.${oci_identity_tag.IDCSAuditLogTag.name}" = var.release }
}

resource "oci_functions_function" "postauditlogs" {
  depends_on     = [null_resource.IdcsAuditLogPush2OCIR]
  application_id = oci_functions_application.IdcsAuditLogApp.id
  display_name   = "postauditlogs-${var.deployment_name}"
  image          = "${local.ocir_docker_repository}/${local.namespace}/${var.ocir_repo_name}/postauditlogs:0.0.1"
  memory_in_mbs  = "1024"
  config = {
    "REGION" : "${var.region}"
    "TRACKER_BUCKET" : "${oci_objectstorage_bucket.tracker-bucket.name}",
    "TRACKER_OBJECT_NAME" : "postauditlogs-${var.deployment_name}-tracker-timestamp",
    "IDCS_URL" : "${var.idcs_url}"
    "IDCS_CLIENTID" : "${var.idcs_clientid}"
    "IDCS_CLIENT_VAULTSECRET" : "${var.idcs_client_vaultsecret}"
    "LOG_GROUP_ID" : "${var.log_analytics_group_id}"
    "LOG_SOURCE" : "${var.log_source}"
    "ENTITY_ID" : "${oci_log_analytics_log_analytics_entity.test_log_analytics_entity.id}"
  }
  #defined_tags = { "${oci_identity_tag_namespace.IDCSAuditLogTagNamespace.name}.${oci_identity_tag.IDCSAuditLogTag.name}" = var.release }
}

resource "oci_logging_log" "log_on_fn_invoke" {
  display_name = "log_on_fn_invoke"
  log_group_id = oci_logging_log_group.log_group.id
  log_type     = "SERVICE"

  configuration {
    source {
      category    = "invoke"
      resource    = oci_functions_application.IdcsAuditLogApp.id
      service     = "functions"
      source_type = "OCISERVICE"
    }
    compartment_id = var.compartment_ocid
  }
  is_enabled = true
  #retention_duration = var.retention_duration
}
