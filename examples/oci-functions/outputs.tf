# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "vcn_id" {
  description = "VCN OCID created for the Functions application subnet."
  value       = oci_core_vcn.this.id
}

output "subnet_id" {
  description = "Public subnet OCID attached to the Functions application."
  value       = oci_core_subnet.public.id
}

output "functions_application_id" {
  description = "OCI Functions application OCID."
  value       = oci_functions_application.this.id
}

output "functions_application_subnet_ids" {
  description = "Subnet OCIDs attached to the OCI Functions application."
  value       = oci_functions_application.this.subnet_ids
}

output "function_id" {
  description = "OCI Function OCID."
  value       = oci_functions_function.this.id
}

output "function_invoke_endpoint" {
  description = "Invoke endpoint for the OCI Function."
  value       = oci_functions_function.this.invoke_endpoint
}
