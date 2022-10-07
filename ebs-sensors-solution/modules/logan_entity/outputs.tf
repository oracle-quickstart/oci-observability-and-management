# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "entity_details" {
  description = "Log Analytics entity"
  value       = oci_log_analytics_log_analytics_entity.log_analytics_entity
}

output "entity_id" {
  description = "Log Analytics entity ID"
  value       = oci_log_analytics_log_analytics_entity.log_analytics_entity.id
}
