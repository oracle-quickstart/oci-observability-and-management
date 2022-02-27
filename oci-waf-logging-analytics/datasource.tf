# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

data "oci_identity_tenancy" "tenancy" {
  #Required
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_tenancy" "tenant_details" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_regions" "home_region" {
  filter {
    name   = "key"
    #values = [data.oci_identity_tenancy.tenant_details.home_region_key]
    values = [data.oci_identity_tenancy.tenancy.home_region_key]
  }
}

data "oci_objectstorage_namespace" "os-namespace" {
    #Optional
    #compartment_id = var.tenancy_ocid
}

data "oci_load_balancer_load_balancers" "test_load_balancers" {
    #Required
    compartment_id = var.compartment_ocid
}

data "oci_core_instance" "test_instance" {
    #Required
    instance_id = "ocid1.instance.oc1.ap-sydney-1.anzxsljrbulluiqcdqpmztz6kwqff3keqzaulezbhwzouyhmu7kh5z4sbqhq"
}
