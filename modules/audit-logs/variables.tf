# Copyright 2021 Oracle Corporation and/or affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

variable "la_namespace" {
  type = string
}

variable "compartment_ocid" {
  type = string
}


variable "audit_log_group_ocid" {
  type = string
  default = null
}

variable "create_log_analytics_audit_log_group" {
	type    = bool
	default = false
}

variable "log_analytics_audit_log_group_name" {
  type = string
  default ="logging_analytics_ociaudit"
}

variable "audit_service_connector_name" {
  type = string
  default = "logging_analytics_automatic_ociaudit_logs"
}
variable "logan-audit-id" {
  type = string
  default = null
} 
