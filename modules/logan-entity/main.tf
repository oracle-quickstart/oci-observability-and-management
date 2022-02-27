# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "oci_log_analytics_log_analytics_entity" "log_analytics_entity" {
    #Required
    compartment_id = var.compartment_id
    entity_type_name = var.entity_type_name
    name = var.name
    namespace = var.namespace
    management_agent_id = var.oci_management_agent_management_agent_id
    #Optional
    #cloud_resource_id = oci_log_analytics_cloud_resource.test_cloud_resource.id
    #defined_tags = {"foo-namespace.bar-key"= "value"}
    #freeform_tags = {"bar-key"= "value"}
    #hostname = var.log_analytics_entity_hostname
    #management_agent_id = oci_management_agent_management_agent.test_management_agent.id
    #properties = var.log_analytics_entity_properties
    #source_id = oci_log_analytics_source.test_source.id
    #timezone_region = var.log_analytics_entity_timezone_region
}
