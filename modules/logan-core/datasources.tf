# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

data "oci_objectstorage_namespace" "os-namespace" {
}
data "oci_log_analytics_namespace" "la-namespace" {
  namespace = data.oci_objectstorage_namespace.os-namespace.namespace
}
