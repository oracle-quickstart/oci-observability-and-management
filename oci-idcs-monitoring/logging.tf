## Copyright (c) 2021, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_logging_log_group" "log_group" {
  compartment_id = var.compartment_ocid
  display_name   = "idcs-log_group-${random_id.tag.hex}"
}

