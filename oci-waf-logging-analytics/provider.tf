# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

terraform {
  required_providers {
    oci = {
      source = "hashicorp/oci"
      version = "4.61.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  region           = var.region
}

provider "oci" {
  alias            = "home"
  tenancy_ocid     = var.tenancy_ocid
  region           = local.home_region
}
