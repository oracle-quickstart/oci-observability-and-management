# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Global variables

variable "default_compartment_id" {
  type        = string
  description = "The default compartment OCID to use for resources (unless otherwise specified)."
}

variable "default_defined_tags" {
  type        = map(string)
  description = "The different defined tags that are applied to each object by default."
  default     = {}
}

variable "default_freeform_tags" {
  type        = map(string)
  description = "The different freeform tags that are applied to each object by default."
  default     = {}
}

# VCN-specific variables
variable "vcn_options" {
  type = object({
    display_name   = string,
    compartment_id = string,
    defined_tags   = map(string),
    freeform_tags  = map(string),
    cidr           = string,
    enable_dns     = bool,
    dns_label      = string
  })
  description = "Parameters for customizing the VCN."
  default = null
}

variable "existing_vcn_id" {
  type        = string
  description = "The OCID of an existing VCN. Only used when vcn_options is null."
  default     = null
}

# IGW-specific variables
variable "create_igw" {
  type        = bool
  description = "Whether or not to create a IGW in the VCN (default: false)."
  default     = false
}

variable igw_options {
  type = object({
    display_name   = string,
    compartment_id = string,
    defined_tags   = map(string),
    freeform_tags  = map(string),
    enabled        = bool
  })
  description = "Parameters for customizing the IGW."
  default = {
    display_name   = null
    compartment_id = null
    defined_tags   = null
    freeform_tags  = null
    enabled        = null
  }
}

# NATGW-specific variables
variable "create_natgw" {
  type        = bool
  description = "Whether or not to create a NAT Gateway in the VCN (default: false)."
  default     = false
}

variable natgw_options {
  type = object({
    display_name   = string,
    compartment_id = string,
    defined_tags   = map(string),
    freeform_tags  = map(string),
    block_traffic  = bool
  })
  description = "Parameters for customizing the NATGW."
  default = {
    display_name   = null
    compartment_id = null
    defined_tags   = null
    freeform_tags  = null
    block_traffic  = null
  }
}


# SVCGW-specific variables
variable "create_svcgw" {
  type        = bool
  description = "Whether or not to create a Service Gateway in the VCN (default: false)."
  default     = false
}

variable svcgw_options {
  type = object({
    display_name   = string,
    compartment_id = string,
    defined_tags   = map(string),
    freeform_tags  = map(string),
    services       = list(string)
  })
  description = "Parameters for customizing the SVCGW."
  default = {
    display_name   = null
    compartment_id = null
    defined_tags   = null
    freeform_tags  = null
    services       = []
  }
}

# DRG-specific variables
variable "create_drg" {
  type        = bool
  description = "Whether or not to create a Dynamic Routing Gateway in the VCN (default: false)."
  default     = false
}

variable drg_options {
  type = object({
    display_name   = string,
    compartment_id = string,
    defined_tags   = map(string),
    freeform_tags  = map(string),
    route_table_id = string
  })
  description = "Parameters for customizing the DRG."
  default = {
    display_name   = null
    compartment_id = null
    defined_tags   = null
    freeform_tags  = null
    route_table_id = null
  }
}

# Routing policies
variable route_tables {
  type = map(object({
    compartment_id  = string,
    defined_tags   = map(string),
    freeform_tags  = map(string),
    route_rules     = list(object({
      next_hop_id   = string,
      dst_type      = string,
      dst           = string
    }))
  }))
  description = "The Route Tables that should exist in the VCN. Each Route Table typically represents a unique routing policy which can be used by one or more subnets."
  default = {}
}

# DHCP Options
variable dhcp_options {
  type = map(object({
    compartment_id      = string,
    server_type         = string,
    search_domain_name  = string,
    forwarder_1_ip      = string,
    forwarder_2_ip      = string,
    forwarder_3_ip      = string
  }))
  description = "The DHCP Options that should exist in the VCN. Typically there is need for only two DHCP Options (one using the built-in VCN/Internet resolver and the other using custom forwarders)."
  default = {}
}
