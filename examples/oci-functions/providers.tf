# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  region       = var.region
}
