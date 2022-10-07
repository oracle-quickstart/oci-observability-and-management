# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "compartment_id" {
  type        = string
  description = "Compartment Identifier"
}

variable "entity_type_name" {
  type        = string
  description = "Log analytics entity type name"
}

variable "name" {
  type        = string
  description = "Log analytics entity name"
}

variable "namespace" {
  type        = string
  description = "The Logging Analytics namespace used for the request."
}

variable "management_agent_id" {
  type        = string
  description = "The OCID of the Management Agent."
}

variable "properties" {
  type        = map
  description = "The name/value pairs for parameter values to be used in file patterns specified in log sources."
}

#variable "cloud_resource_id" {
#  type        = string
#  description = "The OCID of the Cloud resource which this entity is a representation of."
#}
