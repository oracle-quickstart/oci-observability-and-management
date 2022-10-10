# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "compartment_ocid" {}
variable "tenancy_ocid" {}
variable "region" {}
variable "metric_compartment_id" {}
variable "metric_compartment_id_in_subtree" {
  default = true
}
variable "destinations_topic_ids" {
  default = ""
}
variable "create_empty_topic" {}
variable "stackId" {}
variable "customizeAgentAlarms" {
  default = false
}
variable "customizeLoganAlarms" {
  default = false
}
variable "needLoggingAnalyticsMetrics" {
  default = true
}
variable "cpuAlarm" {
  default = true
}
variable "cpuAlarmInterval" {
  default = 5
}
variable "cpuAlarmThreshold" {
  default = 70
}
variable "cpuAlarmSeverity" {
  default = "CRITICAL"
}
variable "diskAlarm" {
  default = true
}
variable "diskAlarmInterval" {
  default = 5
}
variable "diskAlarmThreshold" {
  default = 1000
}
variable "diskAlarmSeverity" {
  default = "CRITICAL"
}
variable "memoryAlarm" {
  default = true
}
variable "memoryAlarmInterval" {
  default = 5
}
variable "memoryAlarmThreshold" {
  default = 600
}
variable "memoryAlarmSeverity" {
  default = "CRITICAL"
}
variable "availabilityAlarm" {
  default = true
}
variable "availabilityAlarmInterval" {
  default = 5
}
variable "availabilityAlarmSeverity" {
  default = "CRITICAL"
}
variable "loganDataSizeAlarm" {
  default = true
}
variable "loganDataSizeAlarmInterval" {
  default = 15
}
variable "loganDataSizeAlarmThreshold" {
  default = 0
}
variable "loganDataSizeAlarmSeverity" {
  default = "CRITICAL"
}
variable "loganUploadFailureAlarm" {
  default = true
}
variable "loganUploadFailureAlarmInterval" {
  default = 5
}
variable "loganUploadFailureAlarmThreshold" {
  default = 0
}
variable "loganUploadFailureAlarmSeverity" {
  default = "CRITICAL"
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  region           = var.region
  version          = 3.66
}