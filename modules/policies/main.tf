# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals{
  #policy_name = format("%s%s","logging-analytics_service_policies",formatdate("DDMMMYYYYhhmmZZZ", timestamp()))
    policy_name = "logging-analytics_service_policies"
}

resource "oci_identity_policy" "logan_servie_policies" {
    compartment_id  = var.compartment_ocid
    description     = "Logging Analytics Service Policies"
    name            = local.policy_name
    statements      = var.policy_statements
}
