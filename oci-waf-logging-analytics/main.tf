# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Onboard and create required policies
module "logan-core" {
  source       = "../modules/logan-core"
  tenancy_ocid = var.tenancy_ocid
  depends_on = [
    module.service_policies
  ]
  onboard_logging_analytics = var.onboard_logging_analytics
}

# User groups
#module "iam" {
#  source            = "../modules/iam"
#  tenancy_ocid      = var.tenancy_ocid
#  compartment_ocid  = var.compartment_ocid
#  current_user_ocid = var.current_user_ocid
#  policy_statements = local.superadmins_policy_statements
#
#  providers = {
#    oci = oci.home
#  }
#}

module "service_policies" {
  source            = "../modules/policies"
  compartment_ocid  = var.tenancy_ocid
  policy_statements = local.service_policy_statements
  providers = {
    oci = oci.home
  }
}

# Enable WAF and Log Collection from LB + WAF Logs
module "regional_waf" {
  source                   = "../modules/waf"
  compartment_id           = var.compartment_ocid
  load_balancer_id         = var.waf_lb_ocid
}

# Create Log Group
module "waf_la_log_group" {
  source           = "../modules/logan-log-group"
  la_namespace     = module.logan-core.logan_namespace
  compartment_ocid = var.compartment_ocid
  log_analytics_log_group_name = var.waf_log_group_name
}

# Enable LB + WAF Log Collection to Logging Analytics
module "waf_logs_service_connector" {
  count                  = var.configure_waf_logs ? 1 : 0
  source                 = "../modules/sch"
  compartment_ocid       = var.compartment_ocid
  la_namespace           = module.logan-core.logan_namespace
  logging_log_group_ocid = module.regional_waf.log_group_ocid
  la_log_group_ocid      = module.waf_la_log_group.log_group_id
}

module "install-dashbaords" {
  source            = "../modules/dashboards"
  compartment_ocid  = var.compartment_ocid
  dashboard_files   = var.dashboard_files
  depends_on = [
    module.logan-core
  ]
}

