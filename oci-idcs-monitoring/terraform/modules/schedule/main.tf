resource "oci_apigateway_gateway" "test_gateway" {
    #Required
    compartment_id = var.compartment_ocid
    endpoint_type = "PUBLIC"
    subnet_id = var.subnet_ocid
    display_name = "${var.gateway_name}"
}

resource "oci_apigateway_deployment" "test_deployment" {
    #Required
    compartment_id = var.compartment_ocid
    gateway_id = oci_apigateway_gateway.test_gateway.id
    #path_prefix = "/fn"
    path_prefix = var.pathprefix

    #Optional
    #display_name = "IdcsLogFnEndpoint-${var.deployment_name}"
    display_name = "${var.gateway_deployment_name}"

    specification {
        routes {
            backend {
                type        = "ORACLE_FUNCTIONS_BACKEND"
                #function_id = oci_functions_function.postauditlogs.id 
                function_id = var.function_id
            }
            #path = "/postauditlogs-${var.deployment_name}"
            path = "${var.path}"
            methods = ["GET"]
        }
    }
}


resource "oci_health_checks_http_monitor" "api_gw_hc" {
  #Required
  compartment_id = "${var.compartment_ocid}"
  display_name = "${var.healthcheck_name}"
  interval_in_seconds = var.interval
  protocol = "HTTPS"
  targets = [oci_apigateway_gateway.test_gateway.hostname]
  #Optional
  is_enabled = true
  method = "GET"
  #path = "/fn/postauditlogs-${var.deployment_name}"
  path = "${var.pathprefix}${var.path}"
  timeout_in_seconds = var.timeout
  vantage_point_names = [ 
      "aws-sfo"
  ]
}

resource "oci_logging_log" "gw_access" {
  display_name = "${var.access_log_name}"
  #display_name = "IdcsApiGateway-access"
  log_group_id = var.log_group_id
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
  display_name = "${var.exec_log_name}"
  log_group_id = var.log_group_id
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
