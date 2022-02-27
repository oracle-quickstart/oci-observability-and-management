variable "compartment_id" {type = string} 
variable "entity_type_name" {type = string} 
variable "name" {type = string} 
variable "namespace" {type = string} 

    #Optional
    #cloud_resource_id = oci_log_analytics_cloud_resource.test_cloud_resource.id
    #defined_tags = {"foo-namespace.bar-key"= "value"}
    #freeform_tags = {"bar-key"= "value"}
    #hostname = var.log_analytics_entity_hostname
variable "oci_management_agent_management_agent_id" {type = string}
    #properties = var.log_analytics_entity_properties
    #source_id = oci_log_analytics_source.test_source.id
    #timezone_region = var.log_analytics_entity_timezone_region
