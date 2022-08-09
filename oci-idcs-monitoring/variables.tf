## Copyright (c) 2021, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}

#comment for stack zip file
variable "user_ocid" {}
#comment for stack zip file
variable "fingerprint" {} 
#comment for stack zip file
variable "private_key_path" {}

variable "compartment_ocid" {}
variable "region" {}
variable "idcs_url" {}
variable "idcs_clientid" {}
variable "idcs_cred_vault_compartment" {}
variable "idcs_client_vaultsecret" {}
variable "log_analytics_group_id" {}
variable "ocir_user_name" {}
variable "ocir_user_password" {}
variable "log_analytics_entity_name" {}

variable "deployment_name" {
    default = "test"
}

variable "release" {
  description = "Reference IDCS Audit Log Exporter Release (OCI Log Analytics)"
  default     = "1.0.0"
}

variable "tracker-bucket" {
  default = "idcs-collector-bucket"
}

variable "VCN-CIDR" {
  default = "10.0.0.0/16"
}

variable "fnsubnet-CIDR" {
  default = "10.0.1.0/24"
}

variable "log_source" {
  default = "IDCS Audit API Logs"
}

variable "ocir_repo_name" {
  default = "loganalytics"
}

variable "setup_policies" {
  default = true
}

variable "dashboard_files" {
  type = set(string)
  default = ["IDCS_Audit_Analysis.json"]
  #default = ["WAF_Activity_Overview.json"]
}
