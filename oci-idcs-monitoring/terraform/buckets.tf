## Copyright (c) 2022, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "oci_objectstorage_namespace" "bucket_namespace" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "tracker-bucket" {
  compartment_id        = var.compartment_ocid
  name                  = "${var.tracker-bucket}-${random_id.tag.hex}"
  namespace             = data.oci_objectstorage_namespace.bucket_namespace.namespace
#  versioning            = "Enabled"
}
