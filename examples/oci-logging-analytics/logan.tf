# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
locals{
    audit_auto_policy_name= format("%s%s","SchPolicy_audit_logAnalytics_",formatdate("DDMMMYYYYhhmmZZZ", timestamp()))
    audit_loggroup_id = "${oci_log_analytics_log_analytics_log_group.audit-loganalytics-group.0.id}"
}

provider "oci" {
  alias = "oci_home_1"
  tenancy_ocid = var.tenancy_ocid
  region       = [for i in data.oci_identity_region_subscriptions.this.region_subscriptions : i.region_name if i.is_home_region == true][0]
}

resource "oci_log_analytics_namespace" "logging_analytics_namespace" {
  #Required
  count          = var.onboard_logging_analytics == "yes" ? 1 : 0
  compartment_id = local.tenancy_id
  is_onboarded   = true
  namespace      = data.oci_identity_tenancy.this.name
  depends_on     = [module.logging_analytics_quickstart]
}

resource "null_resource" "wait_60_seconds" {
  depends_on = [oci_log_analytics_namespace.logging_analytics_namespace]
  provisioner "local-exec" {
    command = "sleep 60s"
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "oci_log_analytics_log_analytics_log_group" "audit-loganalytics-group" {
    #Required
    count = var.create_log_analytics_audit_log_group == "yes" ? 1 : 0
    compartment_id = var.compartment_ocid
    display_name = var.log_analytics_audit_log_group_name
    namespace = data.oci_identity_tenancy.this.name
}

resource "oci_sch_service_connector" "audit-to-logan" {
    #Required
    count = var.create_log_analytics_audit_log_group == "yes" ? 1 : 0
    compartment_id = var.compartment_ocid
    display_name = var.audit_service_connector_name
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
        log_group_id = oci_log_analytics_log_analytics_log_group.audit-loganalytics-group.0.id
        metric = ""
        metric_namespace = ""
        namespace = ""
        object_name_prefix = ""
        stream_id = ""
        topic_id = ""
    }
}

resource "oci_identity_policy" "sch_auto_create_policy" {
    #Required
    provider = oci.oci_home_1
    compartment_id = var.compartment_ocid
    description = "Logging Analytics Audit Policy"
    name = local.audit_auto_policy_name
    statements = ["allow any-user to {LOG_ANALYTICS_LOG_GROUP_UPLOAD_LOGS} in compartment id ${var.compartment_ocid} where all {request.principal.type='serviceconnector', target.loganalytics-log-group.id='${oci_log_analytics_log_analytics_log_group.audit-loganalytics-group.0.id}', request.principal.compartment.id='${var.compartment_ocid}'}"]
}

