# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


output "sch_ocid" {
  description = "Service Connector OCID"
  value       = oci_sch_service_connector.logging-to-logan.id
}

output "sch_name" {
  description = "Service Connector OCID"
  value       = oci_sch_service_connector.logging-to-logan.display_name
}
