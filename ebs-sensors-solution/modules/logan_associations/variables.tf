# variable for upsert associations

variable "entity_compartment_id" {
  type        = string
  description = "Compartment Identifier"
#  default = "ocid1.tenancy.oc1..aaaaaaaa2biiw2clmshec34nq7rcdn2ga6q34rwq3erddvdht5qd4xbaex2a"
}

variable "entity_id" {
  type        = string
  description = "Entity Identifier"
#  default = "ocid1.loganalyticsentity.oc1.phx.amaaaaaaidfzkvqa7xctboqgf4qeqoeeu55vidjfbzwzo2dfwgfcjyjn3yxa"
}

variable "loggroup_id" {
  type        = string
  description = "Log Group Identifier"
#  default = "ocid1.loganalyticsloggroup.oc1.phx.amaaaaaaidfzkvqajw2ee2znhgpacpvvyc33w3k4sbefhl77ilerjmc3w4mq"
}

variable "filepath" {
  type        = string
  description = "Source file Path"
}

variable "auth_type" {}
variable "config_file_profile" {}
