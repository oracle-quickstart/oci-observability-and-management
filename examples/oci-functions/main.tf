# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  tenancy_id = var.tenancy_ocid # Tenancy OCID
}

module "functions_compartment" {
  /* This is a optional step, If you already have a compartment for functions then use that instead */
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

    /* If you already have a compartment then set the compartments to null as shown below:
  compartments = null
  */
    compartments = null
    /*compartments = {
      Functions-Compartment = {
        description    = "Functions Compartment"
        compartment_id = null # The OCID of the parent compartment containing the compartment.
        defined_tags   = null
        freeform_tags  = null
      }
      
    }*/
  }
}

module "functions_quickstart" {

  source = "../../oci-core-modules/oci_iam"
  providers = {
    oci.oci_home = oci.home
  }
  depends_on = [module.functions_compartment]

  iam_config = {

    default_compartment_id = local.tenancy_id # Tenancy OCID
    default_defined_tags   = {}
    default_freeform_tags  = {}
    compartments           = null

    groups = {
      Functions-Group = {
        compartment_id = null #Tenancy OCID
        defined_tags   = null
        freeform_tags  = null
        description    = "Functions Group"
      }
    }

    users = {
      Functions-User-01 = {
        compartment_id = null #Tenancy OCID
        defined_tags   = null
        freeform_tags  = null
        description    = "Functions User"
        email          = "<Your-Functions-User@oracle.com>" 
        groups = ["Functions-Group"]
      }
    }

    dynamic_groups = null

    policies = {
      Functions-Policy = {
        description = "Functions Policy"
        statements = [
          "allow group Functions-Group to use cloud-shell in tenancy",
          "allow group Functions-Group to manage repos in tenancy",
          "allow group Functions-Group to read objectstorage-namespaces in tenancy",
          "allow group Functions-Group to read metrics in tenancy",
          "allow group Functions-Group to manage functions-family in tenancy",
          "allow group Functions-Group to use virtual-network-family in tenancy",
        ]
        version_date   = null
        compartment_id = null # Tenancy OCID
        defined_tags   = null
        freeform_tags  = null
      }
    }
  }
}

