# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# tenancy details
variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}

variable "onboard_logging_analytics" {}
variable "logging_analytics_user_email" {
    default = "Logging_Analytics_User_Email@oracle.com"
}
variable "create_compartment" {}
variable "logging_analytics_compartment_name" {
  default = "Logging-Analytics-Compartment"
}
variable "logging_analytics_group_name" {
  default = "Logging-Analytics-SuperAdmins"
}
variable "create_user" {}
variable "logging_analytics_user_name" {
  default = "Logging-Analytics-User-01"
}
variable "loganalytics_dynamic_group_name" {
  default = "ManagementAgentAdmins"
}
variable "logging_analytics_policy_name" {
  default = "Logging-Analytics-Policy"
}
variable "create_log_analytics_audit_log_group" {}
variable "log_analytics_audit_log_group_name" {
  default ="audit-loganalytics-group"
}
variable "audit_service_connector_name" {
  default = "audit-logging-to-loganalytics"
}