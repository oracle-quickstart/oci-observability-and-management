# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
variable "dashboard_files" {
  description = "Dashboard JSON files"
  type = set(string)
  default = ["sample_db_2.json", "apm_home.json"]
}


variable compartment_ocid {
  description = "Compartment for creating dashboards and saved-searches"
  type = string
}


variable "service_tag" {
  type = object({
    freeformTags = map(string)
    definedTags = map(string)
 })
  default = {freeformTags={}, definedTags={}}
}
