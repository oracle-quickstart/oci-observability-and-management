# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  tenancy_id = var.tenancy_ocid # Tenancy OCID
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
    compartments           = null

    /* If you need to create a compartment then follow the below sample:
    compartments = {
      Logging-Analytics-Compartment = {
        description    = "Logging Analytics Compartment"
        compartment_id = null # The OCID of the parent compartment containing the compartment.
        defined_tags   = null
        freeform_tags  = null
      }*/
    
    /* Optionally you can also create a Agent compartment for Agents and agent keys. 
    Refer: https://docs.oracle.com/en/cloud/paas/logging-analytics/logqs/
    
    Logging-Analytics-Agent-Compartment = {
      description    = "Logging Analytics Agent Compartment"
      compartment_id = null # The OCID of the parent compartment containing the compartment.
      defined_tags   = null
      freeform_tags  = null
    }
    
    }*/
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
      Logging-Analytics-SuperAdmins = {
        compartment_id = null #Tenancy OCID
        defined_tags   = null
        freeform_tags  = null
        description    = "Logging Analytics SuperAdmins Group"
      }
    }

    users = {
      Logging-Analytics-User-01 = {
        compartment_id = null #Tenancy OCID
        defined_tags   = null
        freeform_tags  = null
        description    = "Logging Analytics User"
        email          = var.logging_analytics_user_email != "" ? var.logging_analytics_user_email : "<Your_Logging_Analytics_User_Email>"
        groups = ["Logging-Analytics-SuperAdmins"]
      }
    }

    dynamic_groups = {
      ManagementAgentAdminss = {
        compartment_id = null #Tenancy OCID
        defined_tags   = null
        freeform_tags  = null
        description    = "Logging Analytics Management Agent Dynamic group"
        #matching_rules = ["All {resource.type = 'managementagent', resource.compartment.id = ${module.logging_analytics_compartment.iam_config.compartments["Logging-Analytics-Compartment"].id}}"]
        matching_rules = ["All {resource.type = 'managementagent', resource.compartment.id = ${var.compartment_ocid}}"]
      }
    }

    policies = {
      Logging-Analytics-Policy = {
        description = "Logging Analytics Policy"
        statements = ["allow service loganalytics to READ loganalytics-features-family in tenancy",
          "allow group Logging-Analytics-SuperAdmins to READ compartments in tenancy",
          "allow group Logging-Analytics-SuperAdmins to MANAGE loganalytics-features-family in tenancy",
          /* Use the following policies for production usage.
          "allow group Logging-Analytics-SuperAdmins to MANAGE loganalytics-resources-family in tenancy",
          "allow group Logging-Analytics-SuperAdmins to MANAGE management-dashboard-family in tenancy",
          "allow group Logging-Analytics-SuperAdmins to READ metrics IN tenancy",
          "allow group Logging-Analytics-SuperAdmins TO MANAGE management-agents IN tenancy",
          "allow group Logging-Analytics-SuperAdmins to MANAGE management-agent-install-keys IN tenancy",
          "allow group Logging-Analytics-SuperAdmins to READ users IN tenancy",*/
          "allow dynamic-group ManagementAgentAdminss to MANAGE management-agents IN tenancy",
          "allow dynamic-group ManagementAgentAdminss to USE METRICS IN tenancy",
          "allow dynamic-group ManagementAgentAdminss to {LOG_ANALYTICS_LOG_GROUP_UPLOAD_LOGS} in tenancy",
        "allow dynamic-group ManagementAgentAdminss to USE loganalytics-collection-warning in tenancy"
        ]
        version_date   = null
        compartment_id = null # Tenancy OCID
        defined_tags   = null
        freeform_tags  = null
      }
    }
  }
}

resource "oci_log_analytics_namespace" "log_analytics_namespace" {
  #Required
  count          = var.log_analytics_namespace != "" ? 1 : 0
  compartment_id = local.tenancy_id
  is_onboarded   = true
  namespace      = var.log_analytics_namespace
  depends_on     = [module.logging_analytics_quickstart]
}

data "oci_log_analytics_namespace" "log_analytics_namespace" {
  #Required
  count = 0
  namespace = oci_log_analytics_namespace.log_analytics_namespace[count.index].namespace
}
