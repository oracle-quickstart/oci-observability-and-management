resource "oci_apigateway_gateway" "test_gateway" {
    #Required
    compartment_id = var.compartment_ocid
    endpoint_type = "PUBLIC"
    subnet_id = oci_core_subnet.fnsubnet.id
    display_name = "FunctionAPIGateway-${random_id.tag.hex}"
}

resource "oci_apigateway_deployment" "test_deployment" {
    #Required
    compartment_id = var.compartment_ocid
    gateway_id = oci_apigateway_gateway.test_gateway.id
    path_prefix = "/fn"

    #Optional
    display_name = "IdcsLogFnEndpoint-${var.deployment_name}"

    specification {
        routes {
            backend {
                type        = "ORACLE_FUNCTIONS_BACKEND"
                function_id = oci_functions_function.postauditlogs.id 
            }
            path = "/postauditlogs-${var.deployment_name}"
            methods = ["GET"]
        }
    }
}

resource "oci_logging_log" "gw_access" {
  display_name = "IdcsApiGateway-access"
  log_group_id = oci_logging_log_group.log_group.id
  log_type     = "SERVICE"
  configuration {
    source {
      category    = "access"
      resource    = oci_apigateway_deployment.test_deployment.id
      service     = "apigateway"
      source_type = "OCISERVICE"
    }
    compartment_id = var.compartment_ocid
  }
  is_enabled         = true
  #retention_duration = var.retention_duration
}

resource "oci_logging_log" "gw_exec" {
  display_name = "IdcsApiGateway-exec"
  log_group_id = oci_logging_log_group.log_group.id
  log_type     = "SERVICE"
  configuration {
    source {
      category    = "execution"
      resource    = oci_apigateway_deployment.test_deployment.id
      service     = "apigateway"
      source_type = "OCISERVICE"
    }
    compartment_id = var.compartment_ocid
  }
  is_enabled         = true
  #retention_duration = var.retention_duration
}

