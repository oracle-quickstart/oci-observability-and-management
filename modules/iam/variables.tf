# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


variable "tenancy_ocid" {
   type = string
}

variable "logging_analytics_admin_group_name" {
   type = string
   default = "LoggingAnalytics-SuperAdmins"
}

variable "policy_statements" {
   type = list
   default = null
}

variable "current_user_ocid" {}

variable "compartment_ocid" {
  type = string
}
