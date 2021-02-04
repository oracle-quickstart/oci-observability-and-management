# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "functions_iam_config" {
  description = "functions iam configuration details"
  value       = module.functions_quickstart.iam_config
}

output "functions_network_config" {
  description = "functions network configuration details"
  value       = module.oci_network
}

output "functions_subnet_config" {
  description = "functions subnet configuration details"
  value       = module.oci_subnets
}

output "function_invoke_result" {
  value = oci_functions_invoke_function.this
}
