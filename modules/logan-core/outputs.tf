# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


output "logan_namespace" {
  #value = oci_log_analytics_namespace.logging_analytics_namespace[0].namespace
  value =data.oci_objectstorage_namespace.os-namespace.namespace 
  # value = data.oci_objectstorage_namespace.os-namespace.namespace == null ? oci_log_analytics_namespace.logging_analytics_namespace.0.namespace : local.la_namespace
}

