# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "instance_ocid" {
  type        = string
  description = "This is OCID of an instance where agent is deployed"
}

variable "compartment_ocid" {
  type        = string
  description = "This is OCID of the compartment where instance is placed"
}
