variable "tenancy_ocid" {}

variable "region" {}

variable "apm_domain_id" {}

variable "compartment_ocid" {}

variable "resource_id" {
  default = "Add this to create a new log for the resource"
}

variable "log_id" {
  default = "Don't change to enable logging"
}

variable "log_service" {
  default = "integration"
}

variable "log_category" {
  default = "activitystream"
}