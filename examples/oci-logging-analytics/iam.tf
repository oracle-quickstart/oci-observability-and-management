# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  tenancy_id = var.tenancy_ocid # Tenancy OCID 
  logging_analytics_group_name = var.existing_logging_analytics_group_name !=null ? var.existing_logging_analytics_group_name : var.logging_analytics_group_name

  /* dynamic_group_without_domain = {
      "${var.loganalytics_dynamic_group_name}" = {
        compartment_id = var.tenancy_ocid #Tenancy OCID
        defined_tags   = null
        freeform_tags  = null
        description    = "Logging Analytics Dynamic group"
        matching_rules = ["All {resource.type = 'managementagent', resource.compartment.id = '${var.compartment_ocid}' }"]
      }
  } 
  
  dynamic_group_with_domain = {
      "${var.loganalytics_dynamic_group_name}" = {
        compartment_id = var.tenancy_ocid #Tenancy OCID
        identity_domain_url = var.identity_domain_url
        description    = "Logging Analytics Dynamic group"
        matching_rules = ["All {resource.type = 'managementagent',resource.compartment.id = '${var.compartment_ocid}' }"]
      }
  }  */

  groups_without_domain = {
      "${var.logging_analytics_group_name}" = {
        compartment_id = var.tenancy_ocid #Tenancy OCID
        defined_tags   = null
        freeform_tags  = null
        description    = "Logging Analytics Admins Group"
      }
    }

  groups_with_domain = {
      "${var.logging_analytics_group_name}" = {
        compartment_id = var.tenancy_ocid #Tenancy OCID
        identity_domain_url = var.identity_domain_url
        description    = "Logging Analytics Admins Group"
      }
    }
  
  
  # compartments = {
  #   "${var.logging_analytics_compartment_name}" = {
  #     description    = "Logging Analytics Compartment"
  #     compartment_id = null # The OCID of the parent compartment containing the compartment.
  #     defined_tags   = null
  #     freeform_tags  = null
  #   }
  # }
  
  # find_compartment_id = var.create_compartment == "yes" ? module.logging_analytics_compartment.iam_config.compartments[var.logging_analytics_compartment_name].id : var.compartment_ocid
  # logging_analytics_user_name = var.create_user == "yes" ? var.logging_analytics_user_name : "dummy_logan_placeholder_user"

  # users = {
  #     "${var.logging_analytics_user_name}" = {
  #       compartment_id = null #Tenancy OCID
  #       defined_tags   = null
  #       freeform_tags  = null
  #       description    = "Logging Analytics User"
  #       email          = var.logging_analytics_user_email
  #       groups         = ["${var.logging_analytics_group_name}"]
  #     }
  #   }
}

# module "logging_analytics_compartment" {
#   /* This is a optional step, If you already have a compartment for logging analytics then use that instead */
#   source = "../../oci-core-modules/oci_iam"
#   providers = {
#     oci.oci_home = oci.home
#   }
#   iam_config = {

#     default_compartment_id = local.tenancy_id # Tenancy OCID
#     default_defined_tags   = {}
#     default_freeform_tags  = {}
#     groups                 = null
#     users                  = null
#     policies               = null
#     dynamic_groups         = null
#     compartments           = var.create_compartment == "yes" ? local.compartments : null
#   }
# }

module "logging_analytics_quickstart" {

  source = "../../oci-core-modules/oci_iam"
  providers = {
    oci.oci_home = oci.home
  }
  # depends_on = [module.logging_analytics_compartment]

  iam_config = {

    default_compartment_id = local.tenancy_id # Tenancy OCID
    default_defined_tags   = {}
    default_freeform_tags  = {}
    compartments           = null

    groups = var.create_logging_analytics_group == "no" ? null : (var.identity_domain_enabled == "yes" ? null : local.groups_without_domain)

    groups_with_domain = var.create_logging_analytics_group == "no" ? null : (var.identity_domain_enabled == "yes" ? local.groups_with_domain : null)

    users = null 

    # Starting March 29, 2022, dynamic group policies, related to Management Agent, are not required to be added manually since OCI Management Agent cloud service will automatically enforce the authorization and permissions in the backend.
    dynamic_groups = null
    dynamic_groups_with_domain = null
    #dynamic_groups = var.identity_domain_enabled == "yes" ? null : local.dynamic_group_without_domain
    #dynamic_groups_with_domain = var.identity_domain_enabled == "yes" ? local.dynamic_group_with_domain : null
   
    policies = {
      "${var.logging_analytics_policy_name}" = {
        description = "Logging Analytics Policy"
        statements = ["allow service loganalytics to READ loganalytics-features-family in tenancy",
          "allow group ${local.logging_analytics_group_name} to READ compartments in tenancy",
          "allow group ${local.logging_analytics_group_name} to MANAGE loganalytics-features-family in tenancy",
          "allow group ${local.logging_analytics_group_name} to MANAGE loganalytics-resources-family in tenancy",
          "allow group ${local.logging_analytics_group_name} to MANAGE management-dashboard-family in tenancy",
          "allow group ${local.logging_analytics_group_name} to READ metrics IN tenancy",
          "allow group ${local.logging_analytics_group_name} TO MANAGE management-agents IN tenancy",
          "allow group ${local.logging_analytics_group_name} to MANAGE management-agent-install-keys IN tenancy",
          "allow group ${local.logging_analytics_group_name} to READ users IN tenancy",
          #"allow dynamic-group ${var.loganalytics_dynamic_group_name} to MANAGE management-agents IN tenancy",
          #"allow dynamic-group ${var.loganalytics_dynamic_group_name} to USE METRICS IN tenancy",
          #"allow dynamic-group ${var.loganalytics_dynamic_group_name} to {LOG_ANALYTICS_LOG_GROUP_UPLOAD_LOGS} in tenancy",
          #"allow dynamic-group ${var.loganalytics_dynamic_group_name} to USE loganalytics-collection-warning in tenancy"
        ]
        version_date   = null
        compartment_id = null # Tenancy OCID
        defined_tags   = null
        freeform_tags  = null
      }
    }
  }
}
