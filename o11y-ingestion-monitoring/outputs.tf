# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "cpu_alarm_id" {
  description = "ocid of created Cpu Usage alarm. "
  value       = [oci_monitoring_alarm.this_cpuAlarm[*].id]
}

output "disk_alarm_id" {
  description = "ocid of created Disk space alarm. "
  value       = [oci_monitoring_alarm.this_diskAlarm[*].id]
}

output "memory_alarm_id" {
  description = "ocid of created Memory used alarm. "
  value       = [oci_monitoring_alarm.this_memoryAlarm[*].id]
}

output "availability_alarm_id" {
  description = "ocid of created Availability alarm. "
  value       = [oci_monitoring_alarm.this_availabilityAlarm[*].id]
}

output "loganUploadDataSize_alarm_id" {
  description = "ocid of created Memory used alarm. "
  value       = [oci_monitoring_alarm.this_loganUploadDataSizeAlarm[*].id]
}

output "loganUploadFailure_alarm_id" {
  description = "ocid of created Availability alarm. "
  value       = [oci_monitoring_alarm.this_loganUploadFailureAlarm[*].id]
}

output "notification_topic_id" {
  description = "ocid of Notification Topic Id. "
  value       = [oci_ons_notification_topic.this_notification_topic[*].id]
}