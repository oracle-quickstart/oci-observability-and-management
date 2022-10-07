# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# This module is mainly to help manage a resource that requires some time delays for further processing.

locals {
  minutes = ceil(var.wait_in_minutes)
}

resource "null_resource" "empty" {}

resource "time_sleep" "wait_x_mins" {
  depends_on = [
    null_resource.empty
  ]
  create_duration = "${local.minutes}m"
}
