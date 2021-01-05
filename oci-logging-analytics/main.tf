# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  tenancy_id = var.tenancy_id # Tenancy OCID
}

module "logging_analytics" {
  source = "github.com/oracle-terraform-modules/terraform-oci-tdf-iam"

  providers = {
    oci.oci_home = oci.home
  }

  iam_config = {
    default_compartment_id = local.tenancy_id # Tenancy OCID
    default_defined_tags   = {}
    default_freeform_tags  = {}

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
        email          = "Logging-Analytics-User-01@yahoo.com"
        groups         = ["Logging-Analytics-SuperAdmins"]
      }
    }

    /* If you already have a compartment then set the compartments to null as shown below:
  compartments = null
  */
    compartments = {
      Logging-Analytics-Compartment = {
        description    = "Logging Analytics Compartment"
        compartment_id = null # The OCID of the parent compartment containing the compartment.
        defined_tags   = null
        freeform_tags  = null
      }
      /* Optionally you can also create a Agent compartment for Agents and agent keys. 
       Refer: https://docs.oracle.com/en/cloud/paas/logging-analytics/logqs/
    Logging-Analytics-Agent-Compartment = {
      description    = "Logging Analytics Agent Compartment"
      compartment_id = null # The OCID of the parent compartment containing the compartment.
      defined_tags   = null
      freeform_tags  = null
    }
    */
    }

    dynamic_groups = {
      ManagementAgentAdmins = {
        compartment_id = null # Tenancy OCID
        description    = "Logging Analytics Management Agent Dynamic group"
        instance_ids   = ["<Your_instance_ocid1.instance.oc1.phx.xx>"] 
        defined_tags   = null
        freeform_tags  = null
      }
    }

    policies = {
      Logging-Analytics-Policy = {
        description = "Logging Analytics Policy"
        statements = ["allow service loganalytics to READ loganalytics-features-family in tenancy",
          "allow group Logging-Analytics-SuperAdmins to READ compartments in tenancy",
          "allow group Logging-Analytics-SuperAdmins to MANAGE loganalytics-features-family in tenancy",
          "allow group Logging-Analytics-SuperAdmins to MANAGE loganalytics-resources-family in tenancy",
          "allow group Logging-Analytics-SuperAdmins to MANAGE management-dashboard-family in tenancy",
          "allow group Logging-Analytics-SuperAdmins to READ metrics IN tenancy",
          "allow group Logging-Analytics-SuperAdmins TO MANAGE management-agents IN tenancy",
          "allow group Logging-Analytics-SuperAdmins to MANAGE management-agent-install-keys IN tenancy",
          "allow group Logging-Analytics-SuperAdmins to READ users IN tenancy",
          "allow dynamic-group ManagementAgentAdmins to MANAGE management-agents IN tenancy",
          "allow dynamic-group ManagementAgentAdmins to USE METRICS IN tenancy",
          "allow dynamic-group ManagementAgentAdmins to {LOG_ANALYTICS_LOG_GROUP_UPLOAD_LOGS} in tenancy",
        "allow dynamic-group ManagementAgentAdmins to USE loganalytics-collection-warning in tenancy"]
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
  compartment_id = local.tenancy_id
  is_onboarded   = true
  namespace      = "<Your_Tenancy_Name>"
}

data "oci_log_analytics_namespace" "log_analytics_namespace" {
  #Required
  namespace = oci_log_analytics_namespace.log_analytics_namespace.namespace
}
