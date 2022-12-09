<!--
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-->

# **OCI Management Agent Alarms Quick Start**

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/oracle-quickstart/oci-observability-and-management/releases/download/o11y-ingestion-monitoring-v1.0/o11y-ingestion-monitoring.zip)

## Introduction

This stack creates alarms specific to Management Agent and Logging Analytics metrics.

## Prerequisite

This stack expects the users to have the required IAM policies and permissions to create alarms.

## Stack Details

* This stack creates alarms for Management Agent and Logging Analytics metrics in the selected compartment.
* This stack creates a new notification topic by default without any subscription.
* Users can instead use existing notification topic OCID.
* Under Management Agent Alarms section, this stack creates four critical alarms by default :
    * Agent Availability Alarm
    * CPU Usage Alarm
    * Disk Space Alarm
    * JVM Memory Usage Alarm
* Logging analytics alarms are enabled by default which can be disabled.
* Under Logging Analytics Alarms section, this stack creates two critical alarms by default :
    * Logging analytics upload data size alarm
    * Logging analytics upload failure Alarm
* Users have the option to disable or modify the alarm settings (interval, threshold or severity) for any of the above alarms.

## Using this stack

1. Click on above Deploy to Oracle Cloud button which will redirect you to OCI console and prompt a dialogue box with further steps on deploying this application.
2. Configure the variables for the infrastructure resources that this stack will create when you run the apply job for this execution plan.
3. Review the changes after the configuration fields are updated.

*Note:* For more details on Management Agent metrics please refer
https://docs.oracle.com/iaas/management-agents/doc/agent-metrics.html
