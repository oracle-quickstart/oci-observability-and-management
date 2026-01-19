# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals{
    notification_topic_name = format("%s%s","AgentAlarmTopic_", var.stackId)

    cpuQuery = format("%s%s%s%s", "usageCpu[", var.cpuAlarmInterval, "m].mean() > ", var.cpuAlarmThreshold)
    diskQuery = format("%s%s%s%s", "diskUsageUsed[", var.diskAlarmInterval, "m].mean() > ", var.diskAlarmThreshold)
    memoryQuery = format("%s%s%s%s", "usageRss[", var.memoryAlarmInterval, "m].mean() > ", var.memoryAlarmThreshold)
    availabilityQuery = format("%s%s%s", "agentHealthStatus[", var.availabilityAlarmInterval, "m].absent()")
    loganUploadDataSizeQuery = format("%s%s%s%s", "logCollectionUploadDataSize[", var.loganDataSizeAlarmInterval, "m].sum() <= ", var.loganDataSizeAlarmThreshold)
    loganUploadFailureQuery = format("%s%s%s%s", "logCollectionUploadFailureCount[", var.loganUploadFailureAlarmInterval, "m].sum() > ", var.loganUploadFailureAlarmThreshold)

    cpuAlarmName = format("%s%s", "ManagementAgent CPU Utilization - ", var.stackId)
    diskAlarmName = format("%s%s", "ManagementAgent Disk Space Utilization - ", var.stackId)
    memoryAlarmName = format("%s%s", "ManagementAgent Memory Utilization - ", var.stackId)
    availabilityAlarmName = format("%s%s", "ManagementAgent Availability - ", var.stackId)
    loganDataSizeAlarmName = format("%s%s", "ManagementAgent Log Collection Upload Datasize - ", var.stackId)
    loganUploadFailureAlarmName = format("%s%s", "ManagementAgent Log Collection Upload Failure - ", var.stackId)
}

resource "oci_ons_notification_topic" "this_notification_topic" {
  #Required
  count = var.create_empty_topic ? 1 : 0
  compartment_id = var.compartment_ocid
  name = local.notification_topic_name

  description = "Notification Topic for ManagementAgent alarms"
}

resource "oci_monitoring_alarm" "this_cpuAlarm" {

  count = var.cpuAlarm ? 1 : 0
  #Required
  compartment_id = var.compartment_ocid
  destinations = [var.create_empty_topic ? oci_ons_notification_topic.this_notification_topic[0].id : var.destinations_topic_ids]
  display_name = local.cpuAlarmName
  is_enabled = true
  metric_compartment_id = var.metric_compartment_id
  namespace = "oci_managementagent"
  query = local.cpuQuery
  severity = var.cpuAlarmSeverity

  #Optional
  body = "Percentage Cpu usage of the agent has exceeded the threshold value"
  metric_compartment_id_in_subtree = var.metric_compartment_id == var.tenancy_ocid ? var.metric_compartment_id_in_subtree : false
}

resource "oci_monitoring_alarm" "this_diskAlarm" {

  count = var.diskAlarm ? 1 : 0
  #Required
  compartment_id = var.compartment_ocid
  destinations = [var.create_empty_topic ? oci_ons_notification_topic.this_notification_topic[0].id : var.destinations_topic_ids]
  display_name = local.diskAlarmName
  is_enabled = true
  metric_compartment_id = var.metric_compartment_id
  namespace = "oci_managementagent"
  query = local.diskQuery
  severity = var.diskAlarmSeverity

  #Optional
  body = "Amount of disk space used has exceeded the threshold value"
  metric_compartment_id_in_subtree = var.metric_compartment_id == var.tenancy_ocid ? var.metric_compartment_id_in_subtree : false
}

resource "oci_monitoring_alarm" "this_memoryAlarm" {

  count = var.memoryAlarm ? 1 : 0
  #Required
  compartment_id = var.compartment_ocid
  destinations = [var.create_empty_topic ? oci_ons_notification_topic.this_notification_topic[0].id : var.destinations_topic_ids]
  display_name = local.memoryAlarmName
  is_enabled = true
  metric_compartment_id = var.metric_compartment_id
  namespace = "oci_managementagent"
  query = local.memoryQuery
  severity = var.memoryAlarmSeverity

  #Optional
  body = "Amount of memory consumed by the agent's JVM has exceeded the threshold value"
  metric_compartment_id_in_subtree = var.metric_compartment_id == var.tenancy_ocid ? var.metric_compartment_id_in_subtree : false
}

resource "oci_monitoring_alarm" "this_availabilityAlarm" {

  count = var.availabilityAlarm ? 1 : 0
  #Required
  compartment_id = var.compartment_ocid
  destinations = [var.create_empty_topic ? oci_ons_notification_topic.this_notification_topic[0].id : var.destinations_topic_ids]
  display_name = local.availabilityAlarmName
  is_enabled = true
  metric_compartment_id = var.metric_compartment_id
  namespace = "oci_managementagent"
  query = local.availabilityQuery
  severity = var.availabilityAlarmSeverity

  #Optional
  body = "Agent cannot communicate with the Monitoring Service"
  metric_compartment_id_in_subtree = var.metric_compartment_id == var.tenancy_ocid ? var.metric_compartment_id_in_subtree : false
}

resource "oci_monitoring_alarm" "this_loganUploadDataSizeAlarm" {

  count = (var.needLoggingAnalyticsMetrics && var.loganDataSizeAlarm) ? 1 : 0
  #Required
  compartment_id = var.compartment_ocid
  destinations = [var.create_empty_topic ? oci_ons_notification_topic.this_notification_topic[0].id : var.destinations_topic_ids]
  display_name = local.loganDataSizeAlarmName
  is_enabled = true
  metric_compartment_id = var.metric_compartment_id
  namespace = "oci_logging_analytics"
  query = local.loganUploadDataSizeQuery
  severity = var.loganDataSizeAlarmSeverity

  #Optional
  body = "Log Analyics - Log Collection Upload Data Size has exceeded the limit"
  metric_compartment_id_in_subtree = var.metric_compartment_id == var.tenancy_ocid ? var.metric_compartment_id_in_subtree : false
}

resource "oci_monitoring_alarm" "this_loganUploadFailureAlarm" {

  count = (var.needLoggingAnalyticsMetrics && var.loganUploadFailureAlarm) ? 1 : 0
  #Required
  compartment_id = var.compartment_ocid
  destinations = [var.create_empty_topic ? oci_ons_notification_topic.this_notification_topic[0].id : var.destinations_topic_ids]
  display_name = local.loganUploadFailureAlarmName
  is_enabled = true
  metric_compartment_id = var.metric_compartment_id
  namespace = "oci_logging_analytics"
  query = local.loganUploadFailureQuery
  severity = var.loganUploadFailureAlarmSeverity

  #Optional
  body = "Log Analytics - Log Collection Upload Failures seen"
  metric_compartment_id_in_subtree = var.metric_compartment_id == var.tenancy_ocid ? var.metric_compartment_id_in_subtree : false
}