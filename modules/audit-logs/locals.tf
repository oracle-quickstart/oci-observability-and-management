# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals{
#    audit_auto_policy_name = format("%s%s","sch-policy_audit_logging-analytics_",formatdate("DDMMMYYYYhhmmZZZ", timestamp()))
    audit_loggroup_id      = var.audit_log_group_ocid == null ? oci_log_analytics_log_analytics_log_group.audit-loganalytics-group.0.id : var.audit_log_group_ocid 
}
