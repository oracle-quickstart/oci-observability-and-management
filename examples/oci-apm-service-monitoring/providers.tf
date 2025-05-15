# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


provider "oci" {
  tenancy_ocid        = var.tenancy_ocid
  region              = var.region
  # config_file_profile = "" # Add this for local runs with your profile name
}

provider "oci" {
  alias               = "home"
  tenancy_ocid        = var.tenancy_ocid
  region              = [for i in data.oci_identity_region_subscriptions.this.region_subscriptions : i.region_name if i.is_home_region == true][0]
  # config_file_profile = "" # Add this for local runs with your profile name
}

data "oci_identity_region_subscriptions" "this" {
  tenancy_id = var.tenancy_ocid
}  