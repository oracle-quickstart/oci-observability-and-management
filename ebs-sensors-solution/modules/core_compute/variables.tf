# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "tenancy_id" {
  type        = string
}

variable "compartment_ocid" {
  type        = string
  description = "Compartment Identifier"
}

variable "availability_domain" {
  type        = string
  description = "The availability domain of the instance"
}

variable "subnet_id" {
  type        = string
  description = "The OCID of the subnet to create the VNIC in."
}

variable "public_key" {
  description = "Public SSH keys to be included in the ~/.ssh/authorized_keys file for the default user on the instance. "
}

variable "display_name" {
  type    = string
  default = "Management Agent Host"
}

variable "compute_shape" {
  type    = string
  default = "VM.Standard.E3.Flex"
}

variable "db_name" {
  type        = string
  description = "This is the DB entity name"
}
variable "db_secret_ocid" {
  type        = string
  description = "This is OCID for DB secrets in Vault"
}

variable "db_user" {
  type        = string
  description = "This is the username to connect to DB"
}

variable "log_group_ocid" {
  type        = string
  description = "The unique identifier of the log group to use when auto-associting the log source to eligible entities."
}

variable "namespace" {
  type        = string
  description = "The Logging Analytics namespace used for the request."
}

variable "bucket_name" {
  type        = string
}

variable "file_name" {
  type        = string
}
