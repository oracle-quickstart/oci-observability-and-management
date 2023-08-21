# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# tenancy details
variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}

variable "onboard_logging_analytics" {
  default = false
}

variable "identity_domain_enabled"{
  default = false
}

# variable "logging_analytics_user_email" {
#     default = "Logging_Analytics_User_Email@oracle.com"
# }
# variable "create_compartment" {
#   default = false
# }
# variable "logging_analytics_compartment_name" {
#   default = "Logging-Analytics-Compartment"
# }

variable "create_logging_analytics_group" {
  default = false
}

variable "existing_logging_analytics_group_name" {
  default = null
}

variable "logging_analytics_group_name" {
  default = "logging-analytics-admins"
}

# variable "create_user" {
#   default = false
# }
# variable "logging_analytics_user_name" {
#   default = "Logging-Analytics-User-01"
# }

#variable "loganalytics_dynamic_group_name" {
  #default = "management-agent-admins"
#}

variable "logging_analytics_policy_name" {
  default = "logging-analytics-policy"
}

variable "create_log_analytics_audit_log_group" {}

variable "log_analytics_audit_log_group_name" {
  default ="audit-loggroup"
}
variable "audit_service_connector_name" {
  default = "audit-logs-sch-connector"
}

variable identity_domain_url{
    default = "https://idcs-xxxxx.identity.oraclecloud.com:443"
}
