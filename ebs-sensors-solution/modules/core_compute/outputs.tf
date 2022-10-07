# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "host_details" {
  description = "Host details"
  value       = oci_core_instance.mgmtagent_instance
}
