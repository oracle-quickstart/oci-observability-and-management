data "oci_functions_pbf_listings" "log_sender_pbf_listings" {
    name = "APM Log Sender"
}

data "oci_logging_log_groups" "test_log_groups" {
    #Required
    compartment_id = var.compartment_ocid
}

locals {
    pbflisting_ocid = data.oci_functions_pbf_listings.log_sender_pbf_listings.pbf_listings_collection[0]["items"][0].id
    function_config        = { "APM_DOMAIN_ID" : var.apm_domain_id }
    log_source_map = {
        for log in data.oci_logging_log_groups.test_log_groups.log_groups : log.display_name => log
        }
}

data "oci_logging_log" "logs" {
  for_each = local.log_source_map

  log_group_id = each.value.id
  log_id = var.log_id
}

locals {
  log_group_id = [
    for name, d in data.oci_logging_log.logs : d.log_group_id if d.log_group_id != null
  ]
}

### Enable logging for the resource if the log_id isn't set
resource "oci_logging_log_group" "service_monitoring_log_group" {
    count = var.log_id == "Don't change to enable logging" ? 1 : 0

    compartment_id = var.compartment_ocid
    display_name = "apm-service-monitoring-log-group"
    description = "Log group for service monitoring by APM"
}

resource "oci_logging_log" "service_monitoring_log" {
    count = var.log_id == "Don't change to enable logging" ? 1 : 0

    display_name = "service-monitoring-log"
    log_group_id = oci_logging_log_group.service_monitoring_log_group[count.index].id
    log_type = "SERVICE"

    configuration {
        source {
            category = var.log_category
            service  = var.log_service
            resource = var.resource_id
            source_type = "OCISERVICE"
        }
    }
}

### Creates the application that should contain the function
resource "oci_functions_application" "service_monitoring_application" {
  compartment_id = var.compartment_ocid
  display_name   = "apm-service-monitoring-app"
  subnet_ids     = [module.oci_subnets.subnets.public.id]
  shape          = "GENERIC_ARM"
}

### Creates the PBF function that sends the logs to the APM collector
resource "oci_functions_function" "service_monitoring_function" {
  application_id = oci_functions_application.service_monitoring_application.id
  display_name   = "apm-service-monitoring-function"
  memory_in_mbs  = "1024"

  timeout_in_seconds = 120
  source_details {
        pbf_listing_id = local.pbflisting_ocid
        source_type = "PRE_BUILT_FUNCTIONS"
  }
  config         = local.function_config
}

### Creates the policies for the connector and PBF
resource "oci_identity_policy" "function_policies" {
  provider       = oci.home
  compartment_id = var.compartment_ocid
  description    = "Policies for the function for the service monitoring integration"
  name           = "service-monitoring-integration-policies"
  statements     = [
    "ALLOW any-user TO {APM_DOMAIN_DATA_UPLOAD} in compartment id ${var.compartment_ocid} WHERE ALL { request.principal.id='${oci_functions_function.service_monitoring_function.id}' }",
    "ALLOW any-user TO read apm-domains in compartment id ${var.compartment_ocid} WHERE ALL { request.principal.id='${oci_functions_function.service_monitoring_function.id}' }",
    "allow any-user to use fn-function in compartment id ${var.compartment_ocid} where all {request.principal.type='serviceconnector', request.principal.compartment.id='${var.compartment_ocid}'}",
    "allow any-user to use fn-invocation in compartment id ${var.compartment_ocid} where all {request.principal.type='serviceconnector', request.principal.compartment.id='${var.compartment_ocid}'}"
  ]
}

### Creates the connector which connects the log and PBF
resource "oci_sch_service_connector" "service_monitoring_connector" {
    compartment_id = var.compartment_ocid
    display_name = "Service-monitoring-connector"
    description = "Connects the Log Sender PBF with the log resource to enable the monitoring."

    source {
        kind = "logging"

        log_sources {
            compartment_id = var.compartment_ocid
            log_group_id = var.log_id == "Don't change to enable logging" ? oci_logging_log_group.service_monitoring_log_group[0].id : local.log_group_id[0]
            log_id = var.log_id == "Don't change to enable logging" ? oci_logging_log.service_monitoring_log[0].id : var.log_id
        }
    }
    target {
        kind = "functions"
        
        function_id = oci_functions_function.service_monitoring_function.id
    }
}
