### This is necessary to get the name of the compartment which will be used to create the policy
data "oci_identity_compartment" "policy_compartment" {
  id = var.compartment_ocid
}

locals {
  ocir_repo_name         = "apm-data-exporter-repository"
  function_name          = "apm-data-exporter"
  ocir_docker_repository = "iad.ocir.io"
  compartment_name       = data.oci_identity_compartment.policy_compartment.name
  function_config        = { "apm_domain_id" : var.apm_domain_id }
}

### Creates the application that should the function
resource "oci_functions_application" "this" {
  compartment_id = var.compartment_ocid
  display_name   = "apm-data-exporter-app"
  subnet_ids     = [module.oci_subnets.subnets.public.id]
  shape          = "GENERIC_ARM"
}

### Creates the function that will be called
resource "oci_functions_function" "new_function" {
  depends_on     = [null_resource.FnPush2OCIR]
  application_id = oci_functions_application.this.id
  display_name   = "apm-data-exporter"
  image          = "${local.ocir_docker_repository}/${local.namespace}/${local.ocir_repo_name}/${local.function_name}:0.0.1"
  memory_in_mbs  = "128"

  timeout_in_seconds = 120
  config         = local.function_config
}

### This creates the policy statments needed to allow the function to access trace data in the compartment, to access data in a different compartment, change the compartment name in the statements bellow or add new statements
resource "oci_identity_policy" "function_policy" {
  provider       = oci.home
  compartment_id = var.compartment_ocid
  name           = "apm-data-exporter-policy"
  description    = "Policy needed to allow the function be able to query APM data."
  statements = [
    "ALLOW any-user TO {APM_DOMAIN_READ} IN COMPARTMENT ${local.compartment_name} WHERE ALL { request.principal.id='${oci_functions_function.new_function.id}' }	",
    "ALLOW any-user TO read apm-domains IN COMPARTMENT ${local.compartment_name} WHERE ALL { request.principal.id='${oci_functions_function.new_function.id}' }"
  ]
}

### This creates the policy statments needed to allow ApiGateway to call the function
resource "oci_identity_policy" "gtw_policy" {
  provider       = oci.home
  compartment_id = var.compartment_ocid
  name           = "apm-data-exporter-gtway-policy"
  description    = "Policy needed to allow ApiGateway to call the function."
  statements = [
    "ALLOW any-user to use functions-family in compartment ${local.compartment_name} where ALL {request.principal.type= 'ApiGateway'}	",
  ]
}

resource "oci_apigateway_gateway" "function_gateway" {
    display_name = "apm-data-exporter-gateway"
    compartment_id = var.compartment_ocid
    endpoint_type = "PUBLIC"
    subnet_id = module.oci_subnets.subnets.public.id
}

resource "oci_apigateway_deployment" "fnc_gtw_deployment" {
  compartment_id = var.compartment_ocid
  gateway_id     = oci_apigateway_gateway.function_gateway.id
  path_prefix    = "/v1"
  display_name   = "apm-data-exporter-gateway-deployment"
  specification {
    routes {
      backend {
          type        = "ORACLE_FUNCTIONS_BACKEND"
          function_id = oci_functions_function.new_function.id
      }
      methods = ["GET"]
      path    = "/query"
    }
  }
}

# This is the URL to call to get the data, replace 'query_result_name' with your background query
output "URL_to_call" {
  value = "${oci_apigateway_deployment.fnc_gtw_deployment.endpoint}/query?query_result_name="
}
