# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Create log group for audit logs
resource "oci_log_analytics_log_analytics_log_group" "audit-loganalytics-group" {
    count          = var.audit_log_group_ocid == null ? 1 : 0
    compartment_id = var.compartment_ocid
    display_name   = var.log_analytics_audit_log_group_name
    namespace      = var.la_namespace
    depends_on     = [null_resource.wait_120_seconds]
}

# Create policy for allowing SCs to upload to a specific logging analytics log-group

# Create service connector
resource "oci_sch_service_connector" "audit-to-logan" {
    compartment_id = var.compartment_ocid
    display_name   = var.audit_service_connector_name
    source {
        #Required
        kind = "logging" 
        log_sources {
            #Optional
            compartment_id = var.compartment_ocid
            log_group_id = "_Audit"
            log_id = ""
        }
    }
    target {
        #Required
        kind = "loggingAnalytics"
        #Optional
        batch_rollover_size_in_mbs = 0
        batch_rollover_time_in_ms = 0
        bucket = ""
        compartment_id = ""
        enable_formatted_messaging = false
        function_id = ""
        log_group_id = var.audit_log_group_ocid == null ? oci_log_analytics_log_analytics_log_group.audit-loganalytics-group.0.id : var.audit_log_group_ocid
        metric = ""
        metric_namespace = ""
        namespace = ""
        object_name_prefix = ""
        stream_id = ""
        topic_id = ""
    }
}

# Wait for two minutes for log-group creation
resource "null_resource" "wait_120_seconds" {
  provisioner "local-exec" {
    command = "sleep 120s"
    interpreter = ["/bin/bash", "-c"]
  }
}
