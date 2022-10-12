# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

terraform {
  required_providers {
    oci = {
      source = "hashicorp/oci"
    }
  }
}

resource "oci_identity_dynamic_group" "dynamic_group" {

  count = var.create_dynamicgroup == true ? 1 : 0

  compartment_id = var.tenancy_ocid
  name           = var.dynamic_group_name
  description    = var.dynamic_group_description
  matching_rule  = var.matching_rule
}

resource "oci_identity_policy" "policies" {
  depends_on = [
    oci_identity_dynamic_group.dynamic_group
  ]
  count = var.create_policies == true ? 1 : 0
  name           = var.policy_name
  description    = var.policy_description
  compartment_id = var.policy_compartment_id
  statements     = var.policy_statements
}
