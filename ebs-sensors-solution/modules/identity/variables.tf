# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "tenancy_ocid" {
  type        = string
  description = "The OCID of the tenancy."
  default     = null
}

variable "dynamic_group_name" {
  type        = string
  description = "The name you assign to the group during creation. The name must be unique across all groups in the tenancy and cannot be changed."
  default     = null
}

variable "dynamic_group_description" {
  type        = string
  description = "The description you assign to the Group."
  default     = null
}

variable "matching_rule" {
  type        = string
  description = "The matching rule to dynamically match an instance certificate to this dynamic group."
  default     = null
}

variable "policy_name" {
  type        = string
  description = "The name you assign to the policy during creation."
}

variable "policy_description" {
  type        = string
  description = "The description you assign to the policy."
}

variable "policy_statements" {
  type        = list(string)
  description = "Consists of one or more policy statements. "
}

variable "policy_compartment_id" {
  type        = string
  description = "The compartment id to assign this policy to."
}

variable "create_dynamicgroup" {
  type        = bool
  description = "Create dynamic group or not"
  default     = true
}

variable "create_policies" {
  type        = bool
  description = "Create policies or not"
  default     = true
}
