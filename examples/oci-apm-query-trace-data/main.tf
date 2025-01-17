### This is necessary to get the name of the compartment which will be used to create the policy
data "oci_identity_compartment" "policy_compartment" {
  id = var.compartment_ocid
}

locals {
  ocir_repo_name         = "apm-trace-querier-repository"
  function_name          = "apm-trace-querier"
  ocir_docker_repository = "iad.ocir.io"
  compartment_name       = data.oci_identity_compartment.policy_compartment.name
}

### Creates the application that should the function
resource "oci_functions_application" "this" {
  compartment_id = var.compartment_ocid
  display_name   = "apm-trace-querier-app"
  subnet_ids     = [module.oci_subnets.subnets.public.id]
  shape          = "GENERIC_ARM"
}

### Creates the function that will be called
resource "oci_functions_function" "new_function" {
  depends_on     = [null_resource.FnPush2OCIR]
  application_id = oci_functions_application.this.id
  display_name   = "apm-trace-querier"
  image          = "${local.ocir_docker_repository}/${local.namespace}/${local.ocir_repo_name}/${local.function_name}:0.0.1"
  memory_in_mbs  = "128"

  timeout_in_seconds = 120
}

### This creates the policy statments needed to allow the function to access trace data in the compartment, to access data in a different compartment, change the compartment name in the statements bellow or add new statements
resource "oci_identity_policy" "function_policy" {
  provider       = oci.home
  compartment_id = var.compartment_ocid
  name           = "apm-trace-querier-policy"
  description    = "Policy needed to allow the function be able to query trace data."
  statements = [
    "ALLOW any-user TO {APM_DOMAIN_READ} IN COMPARTMENT ${local.compartment_name} WHERE ALL { request.principal.id='${oci_functions_function.new_function.id}' }	",
    "ALLOW any-user TO read apm-domains IN COMPARTMENT ${local.compartment_name} WHERE ALL { request.principal.id='${oci_functions_function.new_function.id}' }"
  ]
}

### wait a little while before the function is ready to be invoked and for policies to take effect
## I got the following errors without this wait introduced into the plan
## Error: 404-NotAuthorizedOrNotFound
## Error Message: Authorization failed or requested resource not found
##│Suggestion: Either the resource has been deleted or service Functions Invoke Function need policy to access this resource.
resource "time_sleep" "wait_for_function_to_be_ready" {
  depends_on      = [oci_identity_policy.function_policy]
  create_duration = "60s"
}

### Function invocation to test the function's deployment
resource "oci_functions_invoke_function" "invoke_query_function" {
  depends_on = [time_sleep.wait_for_function_to_be_ready]
  function_id           = oci_functions_function.new_function.id
  invoke_function_body  = var.function_invoke_body
  fn_intent             = "httprequest"
  fn_invoke_type        = "sync"
  base64_encode_content = false
}

output "function_response" {
  value = oci_functions_invoke_function.invoke_query_function.content
}
