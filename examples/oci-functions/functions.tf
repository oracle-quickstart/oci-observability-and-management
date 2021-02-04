# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


locals {
  application_display_name             = "test_app"
  application_config                   = { "name" : "Oracle" }
  function_display_name                = "hello_world"
  function_memory_in_mbs               = 128
  function_timeout_in_seconds          = 120
  function_config                      = { "name" : "Oracle" }
  invoke_function_invoke_function_body = "{\"name\":\"Oracle\"}"
  invoke_function_fn_invoke_type       = "sync"
}

resource "oci_functions_application" "this" {
  #Required
  compartment_id = var.compartment_ocid
  display_name   = local.application_display_name
  subnet_ids     = [module.oci_subnets.subnets.public.id]

  #Optional
  config = local.application_config
}

resource "oci_functions_function" "this" {
  #Required
  depends_on = [module.functions_quickstart]
  application_id = oci_functions_application.this.id
  display_name   = local.function_display_name
  image          = var.function_image
  memory_in_mbs  = local.function_memory_in_mbs

  #Optional
  config             = local.function_config
  timeout_in_seconds = local.function_timeout_in_seconds
}

/*resource "time_sleep" "wait_60_seconds" {
  depends_on = [oci_functions_function.this]
  create_duration = "60s"
} We need to uncomment it in terraform version 0.14.x*/

resource "null_resource" "wait_60_seconds" {
  depends_on = [oci_functions_function.this]
  provisioner "local-exec" {
    command = "sleep 60s"
    interpreter = ["/bin/bash", "-c"]
  }
}
resource "oci_functions_invoke_function" "this" {

  #depends_on = [time_sleep.wait_60_seconds]
  depends_on = [null_resource.wait_60_seconds]
  #Required
  function_id = oci_functions_function.this.id

  #Optional
  invoke_function_body = local.invoke_function_invoke_function_body
  fn_intent = "cloudevent"
  fn_invoke_type        = local.invoke_function_fn_invoke_type
  base64_encode_content = false
}

