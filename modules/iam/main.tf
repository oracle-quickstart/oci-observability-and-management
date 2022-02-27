# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Create Required policies & SuperAdmin user-group

module "logging_policies" {
  source                = "oracle-terraform-modules/iam/oci//modules/iam-group"
  version               = "2.0.1"
  tenancy_ocid          = var.tenancy_ocid
  group_name            = var.logging_analytics_admin_group_name
  group_description     = "Logging Analytics Administrators Group"
  user_ids              = [var.current_user_ocid]
  policy_compartment_id = var.tenancy_ocid
  policy_name           = "logging-analytics-superadmins-policy"
  policy_description    = "Logging Analytics superadmins policy"
  policy_statements     = var.policy_statements
}
