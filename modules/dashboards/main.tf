# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
  #import_details = templatefile(format("%s/%s/%s", path.root, "contents", each.value), {"compartment_ocid" : "[var.compartment_ocid]", "freeformTags" : "[var.service_tag.freeformTags]" })
  #import_details = templatefile(format("%s/%s/%s", path.root, "contents", each.value), {"compartment_ocid" : "[var.compartment_ocid]"})


resource "oci_management_dashboard_management_dashboards_import" "multiple_dashboard_files" {
  for_each = var.dashboard_files
    import_details = templatefile(format("%s/%s/%s", path.root,"contents", each.value), {"compartment_ocid" : "${var.compartment_ocid}"})
}
