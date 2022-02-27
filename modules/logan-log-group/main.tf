# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Create log group for audit logs
resource "oci_log_analytics_log_analytics_log_group" "loganalytics-log-group" {
    compartment_id = var.compartment_ocid
    display_name   = var.log_analytics_log_group_name
    namespace      = var.la_namespace
    depends_on     = [null_resource.wait_120_seconds]
}

# Wait for two minutes for log-group creation
resource "null_resource" "wait_120_seconds" {
  provisioner "local-exec" {
    command = "sleep 120s"
    interpreter = ["/bin/bash", "-c"]
  }
}
