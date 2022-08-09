## Copyright (c) 2021, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_logging_log_group" "log_group" {
  compartment_id = var.compartment_ocid
  display_name   = "idcs-log_group-${random_id.tag.hex}"
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
