# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "functions_config" {
  description = "functions config details"
  value       = module.functions_quickstart.iam_config
}

output "function_result" {
  value = oci_functions_invoke_function.this
}
