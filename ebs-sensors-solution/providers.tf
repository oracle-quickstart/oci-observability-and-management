# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

provider "oci" {
#  alias        = "current"
  tenancy_ocid = var.tenancy_ocid
# comment for stack zip file
  config_file_profile = var.config_file_profile
  region       = var.region
}

provider "oci" {
  alias        = "home"
  tenancy_ocid = var.tenancy_ocid
# comment for stack zip file
  config_file_profile = var.config_file_profile
  region       = data.oci_identity_region_subscriptions.home_region_subscriptions.region_subscriptions[0].region_name
  disable_auto_retries = "true"
}
