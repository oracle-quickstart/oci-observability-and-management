# Copyright 2021 Oracle Corporation and/or affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

variable "la_namespace" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "logging_log_group_ocid" {
  type = string
  default = null
}

variable "service_connector_name" {
  type = string
  default = "Logging_Analytics_SCH"
}

variable "la_log_group_ocid" {
  type = string
  default = null
}

