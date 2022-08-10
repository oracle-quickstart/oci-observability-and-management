resource "oci_log_analytics_log_analytics_entity" "test_log_analytics_entity" {
    #Required
    compartment_id = var.compartment_ocid
    entity_type_name = "Oracle Identity Cloud Service"
    name = var.log_analytics_entity_name
    namespace = local.namespace

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
