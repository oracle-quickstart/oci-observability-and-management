# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  #la_namespace =  var.onboard_logging_analytics ? module.logan-core[0].logan_namespace: data.oci_objectstorage_namespace.os-namespace.namespace 
  home_region                  = lookup(data.oci_identity_regions.home_region.regions[0], "name")
  la_namespace                 = data.oci_objectstorage_namespace.os-namespace.namespace

  # 
  onboarding_policy            = "Allow service loganalytics to READ loganalytics-features-family in tenancy"
  compartment_read_policy      = "Allow service loganalytics to inspect compartments in tenancy"
  # 
  superadmin_policy_1          = var.create_superadmin_policy == true ?  "Allow group ${var.logging_analytics_admin_group_name} to READ compartments in tenancy": ""
  superadmin_policy_2          = var.create_superadmin_policy == true ?  "Allow group ${var.logging_analytics_admin_group_name} to MANAGE loganalytics-features-family in tenancy" : ""
  superadmin_policy_3          = var.create_superadmin_policy == true ?  "Allow group ${var.logging_analytics_admin_group_name} to MANAGE loganalytics-resources-family in tenancy" : ""
  superadmin_policy_4          = var.create_superadmin_policy == true ?  "Allow group ${var.logging_analytics_admin_group_name} to MANAGE management-dashboard-family in tenancy" : ""
  superadmin_policy_5          = var.create_superadmin_policy == true ?  "Allow group ${var.logging_analytics_admin_group_name} to READ metrics IN tenancy" : ""
  superadmin_policy_6          = var.create_superadmin_policy == true ?  "Allow group ${var.logging_analytics_admin_group_name} TO MANAGE management-agents IN tenancy" : ""
  superadmin_policy_7          = var.create_superadmin_policy == true ?  "Allow group ${var.logging_analytics_admin_group_name} to MANAGE management-agent-install-keys IN tenancy" : ""
  superadmin_policy_8          = var.create_superadmin_policy == true ?  "Allow group ${var.logging_analytics_admin_group_name} to READ users IN tenancy" : ""

  object_storage_logs_policy_1 = "Allow service loganalytics to read buckets in tenancy" 
  object_storage_logs_policy_2 = "Allow service loganalytics to read objects in tenancy"
  bucket_read_policy           = "Allow service loganalytics to {BUCKET_READ} in tenancy"

  event_rule_logs_policy       = "Allow service loganalytics to manage cloudevents-rules in tenancy"
  event_rules_read_policy      = "Allow service loganalytics to {EVENTRULE_READ} in tenancy"

  tags_policy                  = "Allow service loganalytics to use tag-namespaces in tenancy where all {target.tag-namespace.name = /oracle-tags/}"

  load_balancer_logs_policy    = "Allow service loganalytics to {LOAD_BALANCER_READ} in tenancy"

  function_logs_policy         = "Allow service loganalytics to read functions-family in tenancy"

  api_gateway_logs_policy      = "Allow service loganalytics to read api-gateway-family in tenancy"

  vcn_flowlogs_policy          = "Allow service loganalytics to {VNIC_READ} in tenancy"

  waf_firewall_policy          = "Allow service loganalytics to {WEB_APP_FIREWALL_READ} in tenancy"

  sch_policy                   = "Allow any-user to {LOG_ANALYTICS_LOG_GROUP_UPLOAD_LOGS} in compartment id ${var.compartment_ocid} where all {request.principal.type='serviceconnector'}"

  service_policy_statements            = compact([local.onboarding_policy, local.compartment_read_policy,  local.object_storage_logs_policy_1, local.object_storage_logs_policy_2, local.bucket_read_policy, local.event_rule_logs_policy, local.event_rules_read_policy, local.tags_policy, local.load_balancer_logs_policy, local.function_logs_policy, local.api_gateway_logs_policy, local.vcn_flowlogs_policy, local.waf_firewall_policy, local.sch_policy])

  #superadmins_policy_statements  =  var.create_superadmin_policy == true ? compact([local.superadmin_policy_1, local.superadmin_policy_2, local.superadmin_policy_3, local.superadmin_policy_4, local.superadmin_policy_5, local.superadmin_policy_6, local.superadmin_policy_7, local.superadmin_policy_8]) : ""
  superadmins_policy_statements  =  compact([local.superadmin_policy_1, local.superadmin_policy_2, local.superadmin_policy_3, local.superadmin_policy_4, local.superadmin_policy_5, local.superadmin_policy_6, local.superadmin_policy_7, local.superadmin_policy_8])

  namespace = var.onboard_logging_analytics?  data.oci_objectstorage_namespace.os-namespace.namespace : module.logan-core.logan_namespace
}
