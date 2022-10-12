## Copyright © 2022, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "random_id" "tag" {
  byte_length = 2
}

#resource "oci_identity_tag_namespace" "IDCSAuditLogTagNamespace" {
#  provider       = oci.homeregion
#  compartment_id = var.compartment_ocid
#  description    = "IDCSAuditLogTagNamespace"
#  name           = "IDCSAuditLog\\serverless-log-analytics-${random_id.tag.hex}"
#
#  provisioner "local-exec" {
#    command = "sleep 10"
#  }
#}
#
#resource "oci_identity_tag" "IDCSAuditLogTag" {
#  provider         = oci.homeregion
#  description      = "IDCSAuditLogTag"
#  name             = "release"
#  tag_namespace_id = oci_identity_tag_namespace.IDCSAuditLogTagNamespace.id
#
#  validator {
#    validator_type = "ENUM"
#    values         = ["release", "1.0.2"]
#  }
#
#  provisioner "local-exec" {
#    command = "sleep 120"
#  }
#}
