# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


output "audit-log-group" {
  description = "Audit Log Group - Logging Analtyics"
  value       = oci_log_analytics_log_analytics_log_group.audit-loganalytics-group.0.id
}
