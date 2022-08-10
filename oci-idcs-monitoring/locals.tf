## Copyright (c) 2022, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

locals {
  ocir_docker_repository = join("", [lower(lookup(data.oci_identity_regions.oci_regions.regions[0], "key")), ".ocir.io"])
  #  ocir_namespace = lookup(data.oci_identity_tenancy.oci_tenancy, "name" )
  ocir_namespace = lookup(data.oci_objectstorage_namespace.test_namespace, "namespace")
  namespace = lookup(data.oci_objectstorage_namespace.test_namespace, "namespace")
  compartment_name = lookup(data.oci_identity_compartment.test_compartment, "name")
}
