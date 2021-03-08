# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  tenancy_id = var.tenancy_ocid # Tenancy OCID

  compartments = {
    "${var.logging_analytics_compartment_name}" = {
      description    = "Logging Analytics Compartment"
      compartment_id = null # The OCID of the parent compartment containing the compartment.
      defined_tags   = null
      freeform_tags  = null
    }
  }

  find_compartment_id = var.create_compartment == "yes" ? module.logging_analytics_compartment.iam_config.compartments[var.logging_analytics_compartment_name].id : var.compartment_ocid
}

module "logging_analytics_compartment" {
  /* This is a optional step, If you already have a compartment for logging analytics then use that instead */
  source = "../../oci-core-modules/oci_iam"
  providers = {
    oci.oci_home = oci.home
  }
  iam_config = {

    default_compartment_id = local.tenancy_id # Tenancy OCID
    default_defined_tags   = {}
    default_freeform_tags  = {}
    groups                 = null
    users                  = null
    policies               = null
    dynamic_groups         = null
    compartments           = var.create_compartment == "yes" ? local.compartments : null
  }
}

module "logging_analytics_quickstart" {

  source = "../../oci-core-modules/oci_iam"
  providers = {
    oci.oci_home = oci.home
  }
  depends_on = [module.logging_analytics_compartment]

  iam_config = {

    default_compartment_id = local.tenancy_id # Tenancy OCID
    default_defined_tags   = {}
    default_freeform_tags  = {}
    compartments           = null

    groups = {
      "${var.logging_analytics_group_name}" = {
        compartment_id = null #Tenancy OCID
        defined_tags   = null
        freeform_tags  = null
        description    = "Logging Analytics SuperAdmins Group"
      }
    }

    users = {
      "${var.logging_analytics_user_name}" = {
        compartment_id = null #Tenancy OCID
        defined_tags   = null
        freeform_tags  = null
        description    = "Logging Analytics User"
        email          = var.logging_analytics_user_email
        groups         = ["${var.logging_analytics_group_name}"]
      }
    }

    dynamic_groups = {
      "${var.loganalytics_dynamic_group_name}" = {
        compartment_id = null #Tenancy OCID
        defined_tags   = null
        freeform_tags  = null
        description    = "Logging Analytics Management Agent Dynamic group"
        matching_rules = ["All {resource.type = 'managementagent', resource.compartment.id = ${local.find_compartment_id} }"]
      }
    }

    policies = {
      "${var.logging_analytics_policy_name}" = {
        description = "Logging Analytics Policy"
        statements = ["allow service loganalytics to READ loganalytics-features-family in tenancy",
          "allow group ${var.logging_analytics_group_name} to READ compartments in tenancy",
          "allow group ${var.logging_analytics_group_name} to MANAGE loganalytics-features-family in tenancy",
          /* Use the following policies for production usage.
          "allow group ${var.logging_analytics_group_name} to MANAGE loganalytics-resources-family in tenancy",
          "allow group ${var.logging_analytics_group_name} to MANAGE management-dashboard-family in tenancy",
          "allow group ${var.logging_analytics_group_name} to READ metrics IN tenancy",
          "allow group ${var.logging_analytics_group_name} TO MANAGE management-agents IN tenancy",
          "allow group ${var.logging_analytics_group_name} to MANAGE management-agent-install-keys IN tenancy",
          "allow group ${var.logging_analytics_group_name} to READ users IN tenancy",*/
          "allow dynamic-group ${var.loganalytics_dynamic_group_name} to MANAGE management-agents IN tenancy",
          "allow dynamic-group ${var.loganalytics_dynamic_group_name} to USE METRICS IN tenancy",
          "allow dynamic-group ${var.loganalytics_dynamic_group_name} to {LOG_ANALYTICS_LOG_GROUP_UPLOAD_LOGS} in tenancy",
          "allow dynamic-group ${var.loganalytics_dynamic_group_name} to USE loganalytics-collection-warning in tenancy"
        ]
        version_date   = null
        compartment_id = null # Tenancy OCID
        defined_tags   = null
        freeform_tags  = null
      }
    }
  }
}

resource "oci_log_analytics_namespace" "logging_analytics_namespace" {
  #Required
  count          = var.onboard_logging_analytics == "yes" ? 1 : 0
  compartment_id = local.tenancy_id
  is_onboarded   = true
  namespace      = var.tenancy_ocid
  depends_on     = [module.logging_analytics_quickstart]
}

data "oci_log_analytics_namespace" "logging_analytics_namespace" {
  #Required
  #namespace = oci_log_analytics_namespace.logging_analytics_namespace[count.index].namespace
  namespace = var.tenancy_ocid
}
