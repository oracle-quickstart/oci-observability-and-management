# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


output "logging_analytics_config" {
  description = "logging analytics config details"
  value       = module.logging_analytics_quickstart.iam_config
}

output "logging_analytics_namespace" {
  description = "logging analytics namespace"
  value       = data.oci_log_analytics_namespace.logging_analytics_namespace
}

