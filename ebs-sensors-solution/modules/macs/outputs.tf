# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "agent_details" {
  value       = local.updated_details
  description = "Updated Agent details with deployed LOGAN plugin"
}
