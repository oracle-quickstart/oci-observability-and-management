# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "host_ocid" {
  value = module.create_compute_instance.host_details.id
}

#output "dashboard" {
#  value = format("https://cloud.oracle.com/loganalytics/dashboards?id=%s&comp=${var.resource_compartment})", oci_management_dashboard_management_dashboards_import.dashboard.id)
#}


output "agent_dashboard" {
  value = format("https://cloud.oracle.com/macs/%s?dashId=agent_dashboard_100", module.macs_interactions.agent_details.id)
}

output "entity_dashboard" {
  value = format("https://cloud.oracle.com/loganalytics/entityDetails/%s", module.la_entity.entity_details.id)
}
