# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    oci = {
      version = ">= 4.21.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  region           = var.region
}