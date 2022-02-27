# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


output "log_group_id" {
  description = "Log Group - Logging Analtyics"
  value       = oci_log_analytics_log_analytics_log_group.loganalytics-log-group.id
}
