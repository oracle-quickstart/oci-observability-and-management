# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Create service connector
resource "oci_sch_service_connector" "logging-to-logan" {
    compartment_id = var.compartment_ocid
    display_name   = var.service_connector_name
    source {
        #Required
        kind = "logging" 
        log_sources {
            #Optional
            compartment_id = var.compartment_ocid
            log_group_id   = var.logging_log_group_ocid
            log_id         = ""
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
        log_group_id = var.la_log_group_ocid
        metric = ""
        metric_namespace = ""
        namespace = ""
        object_name_prefix = ""
        stream_id = ""
        topic_id = ""
    }
}
