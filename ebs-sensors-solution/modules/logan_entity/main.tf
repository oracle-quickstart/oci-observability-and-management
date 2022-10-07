# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "oci_log_analytics_log_analytics_entity" "log_analytics_entity" {
  compartment_id      = var.compartment_id
  entity_type_name    = var.entity_type_name
  name                = var.name
  namespace           = var.namespace
  management_agent_id = var.management_agent_id
  properties          = var.properties
#  cloud_resource_id   = var.cloud_resource_id
}
