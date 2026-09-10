# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


variable "tenancy_ocid" {
  description = "OCID of the tenancy used by the OCI provider."
  type        = string
}

variable "compartment_ocid" {
  description = "Compartment where networking and OCI Functions resources are created."
  type        = string
}

variable "region" {
  description = "OCI region identifier (for example: us-chicago-1)."
  type        = string
}

variable "resource_name_prefix" {
  description = "Prefix used for generated OCI resource display names."
  type        = string
  default     = "tf-fn"
}

variable "function_image" {
  description = "Full OCIR image path for the function (for example: iad.ocir.io/<namespace>/hello-world:1.0.0)."
  type        = string
}

variable "function_name" {
  description = "Display name for the OCI Function."
  type        = string
}

variable "application_name" {
  description = "Display name for the OCI Functions application."
  type        = string
  default     = "functions-app"
}

variable "function_memory_in_mbs" {
  description = "Function memory allocation in MB."
  type        = number
  default     = 256
}

variable "function_timeout_in_seconds" {
  description = "Function timeout in seconds."
  type        = number
  default     = 30
}

variable "vcn_cidr" {
  description = "CIDR block for the VCN created by this example."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet used by the Functions application."
  type        = string
  default     = "10.20.1.0/24"
}

variable "defined_tags" {
  description = "Defined tags to apply to managed resources."
  type        = map(string)
  default     = {}
}

variable "freeform_tags" {
  description = "Freeform tags to apply to managed resources."
  type        = map(string)
  default     = {}
}

