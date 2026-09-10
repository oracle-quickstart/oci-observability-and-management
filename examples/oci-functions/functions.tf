# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


resource "oci_functions_application" "this" {
  compartment_id = var.compartment_ocid
  display_name   = var.application_name
  subnet_ids     = [oci_core_subnet.public.id]
  defined_tags   = var.defined_tags
  freeform_tags  = var.freeform_tags
}

resource "oci_functions_function" "this" {
  application_id     = oci_functions_application.this.id
  display_name       = var.function_name
  image              = var.function_image
  memory_in_mbs      = var.function_memory_in_mbs
  timeout_in_seconds = var.function_timeout_in_seconds
  defined_tags       = var.defined_tags
  freeform_tags      = var.freeform_tags
}
