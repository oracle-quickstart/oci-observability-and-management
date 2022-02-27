# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
    la_namespace  = data.oci_objectstorage_namespace.os-namespace.namespace
}

# Onboard logging-analytics
resource "oci_log_analytics_namespace" "logging_analytics_namespace" {
  count = var.onboard_logging_analytics ? 1 : 0
  compartment_id = var.tenancy_ocid
  is_onboarded   = true
  namespace      = local.la_namespace
}

# Wait for two minutes 
resource "null_resource" "wait_120_seconds" {
   depends_on    = [oci_log_analytics_namespace.logging_analytics_namespace]
   provisioner "local-exec" {
        command     = "sleep 120s"
        interpreter = ["/bin/bash", "-c"]
  }
}

