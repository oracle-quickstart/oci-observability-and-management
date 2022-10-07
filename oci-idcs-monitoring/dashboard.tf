## Copyright (c) 2022, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_management_dashboard_management_dashboards_import" "multiple_dashboard_files" { 
  for_each = var.dashboard_files 
    import_details = templatefile(format("%s/%s/%s", path.root,"contents", each.value), {"compartment_ocid" : "${var.compartment_ocid}"})
}
