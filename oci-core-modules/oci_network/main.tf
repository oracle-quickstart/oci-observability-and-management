# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#################
# VCN
#################
# default values
locals {
  vcn_options_defaults  = {
    display_name        = "vcn"
    compartment_id      = null
    cidr                = "10.0.0.0/16"
    enable_dns          = true
    dns_label           = var.vcn_options != null ? ( var.vcn_options.enable_dns != false ? "vcn" : null ) : null
  }
  vcn_with_dns          = var.vcn_options != null ? ( (var.vcn_options.enable_dns != null && var.vcn_options.enable_dns == true) || (var.vcn_options.enable_dns == null && local.vcn_options_defaults.enable_dns == true) ) : false
}

# resource definition
resource "oci_core_vcn" "this" {
  count                 = var.vcn_options != null ? 1 : 0

  dns_label             = (local.vcn_with_dns && var.vcn_options.dns_label != null) ? var.vcn_options.dns_label : local.vcn_options_defaults.dns_label
  cidr_block            = var.vcn_options.cidr != null ? var.vcn_options.cidr : local.vcn_options_defaults.cidr
  compartment_id        = var.vcn_options.compartment_id != null ? var.vcn_options.compartment_id : var.default_compartment_id
  display_name          = var.vcn_options.display_name != null ? var.vcn_options.display_name : local.vcn_options_defaults.display_name
  defined_tags          = var.vcn_options.defined_tags != null ? var.vcn_options.defined_tags : var.default_defined_tags
  freeform_tags         = var.vcn_options.freeform_tags != null ? var.vcn_options.freeform_tags : var.default_freeform_tags
}

######################
# Internet Gateway
######################
# default values
locals {
  igw_options_defaults  = {
    display_name        = "igw"
    compartment_id      = null
    enabled             = true
  }
}

# resource definition
resource "oci_core_internet_gateway" "this" {
  count                 = var.create_igw == true ? 1 : 0
  compartment_id        = var.igw_options != null ? ( var.igw_options.compartment_id != null ? var.igw_options.compartment_id : var.default_compartment_id ) : var.default_compartment_id
  vcn_id                = var.vcn_options != null ? oci_core_vcn.this[0].id : var.existing_vcn_id
  display_name          = var.igw_options != null ? ( var.igw_options.display_name != null ? var.igw_options.display_name : local.igw_options_defaults.display_name ) : local.igw_options_defaults.display_name
  enabled               = var.igw_options != null ? ( var.igw_options.enabled != null ? var.igw_options.enabled : local.igw_options_defaults.enabled ) : local.igw_options_defaults.enabled
  defined_tags          = var.igw_options != null ? ( var.igw_options.defined_tags != null ? var.igw_options.defined_tags : var.default_defined_tags ) : var.default_defined_tags
  freeform_tags         = var.igw_options != null ? ( var.igw_options.freeform_tags != null ? var.igw_options.freeform_tags : var.default_freeform_tags ) : var.default_freeform_tags
}

######################
# NAT Gateway
######################
# default values
locals {
  natgw_options_defaults = {
    display_name        = "natgw"
    compartment_id      = null
    block_traffic       = false
  }
}

# resource definition
resource "oci_core_nat_gateway" "this" {
  count                 = var.create_natgw == true ? 1 : 0
  compartment_id        = var.natgw_options != null ? ( var.natgw_options.compartment_id != null ? var.natgw_options.compartment_id : var.default_compartment_id ) : var.default_compartment_id
  vcn_id                = var.vcn_options != null ? oci_core_vcn.this[0].id : var.existing_vcn_id
  display_name          = var.natgw_options != null ? ( var.natgw_options.display_name != null ? var.natgw_options.display_name : local.natgw_options_defaults.display_name ) : local.natgw_options_defaults.display_name
  block_traffic         = var.natgw_options != null ? ( var.natgw_options.block_traffic != null ? var.natgw_options.block_traffic : local.natgw_options_defaults.block_traffic ) : local.natgw_options_defaults.block_traffic
  defined_tags          = var.natgw_options != null ? ( var.natgw_options.defined_tags != null ? var.natgw_options.defined_tags : var.default_defined_tags ) : var.default_defined_tags
  freeform_tags         = var.natgw_options != null ? ( var.natgw_options.freeform_tags != null ? var.natgw_options.freeform_tags : var.default_freeform_tags ) : var.default_freeform_tags
}

######################
# Service Gateway
######################
# default values
locals {
  svcgw_options_defaults = {
    display_name        = "svcgw"
    compartment_id      = null
    services            = []
  }
}

# resource definition
resource "oci_core_service_gateway" "this" {
  count                 = var.create_svcgw == true ? 1 : 0
  compartment_id        = var.svcgw_options != null ? ( var.svcgw_options.compartment_id != null ? var.svcgw_options.compartment_id : var.default_compartment_id ) : var.default_compartment_id
  vcn_id                = var.vcn_options != null ? oci_core_vcn.this[0].id : var.existing_vcn_id
  display_name          = var.svcgw_options != null ? ( var.svcgw_options.display_name != null ? var.svcgw_options.display_name : local.svcgw_options_defaults.display_name ) : local.svcgw_options_defaults.display_name
  defined_tags          = var.svcgw_options != null ? ( var.svcgw_options.defined_tags != null ? var.svcgw_options.defined_tags : var.default_defined_tags ) : var.default_defined_tags
  freeform_tags         = var.svcgw_options != null ? ( var.svcgw_options.freeform_tags != null ? var.svcgw_options.freeform_tags : var.default_freeform_tags ) : var.default_freeform_tags

  dynamic "services" {
    for_each            = var.svcgw_options != null ? ( var.svcgw_options.services != null ? var.svcgw_options.services : local.svcgw_options_defaults.services ) : local.svcgw_options_defaults.services
    content {
      service_id        = services.value
    }
  }
}

######################
# Dynamic Routing Gateway
######################
# default values
locals {
  drg_options_defaults  = {
    display_name        = "drg"
    compartment_id      = null
    route_table_id      = null
  }
}

# resource definitions
resource "oci_core_drg" "this" {
  count                 = var.create_drg == true ? 1 : 0
  ## use drg_options_defaults.compartment_id if drg_options_compartment_id == null? 
  compartment_id        = var.drg_options != null ? ( var.drg_options.compartment_id != null ? var.drg_options.compartment_id : var.default_compartment_id ) : var.default_compartment_id
  display_name          = var.drg_options != null ? ( var.drg_options.display_name != null ? var.drg_options.display_name : local.drg_options_defaults.display_name ) : local.drg_options_defaults.display_name
  defined_tags          = var.drg_options != null ? ( var.drg_options.defined_tags != null ? var.drg_options.defined_tags : var.default_defined_tags ) : var.default_defined_tags
  freeform_tags         = var.drg_options != null ? ( var.drg_options.freeform_tags != null ? var.drg_options.freeform_tags : var.default_freeform_tags ) : var.default_freeform_tags
}
resource "oci_core_drg_attachment" "this" {
  count                 = var.create_drg == true ? 1 : 0
  drg_id                = oci_core_drg.this[0].id
  vcn_id                = var.vcn_options != null ? oci_core_vcn.this[0].id : var.existing_vcn_id
  display_name          = var.drg_options != null ? ( var.drg_options.display_name != null ? var.drg_options.display_name : local.drg_options_defaults.display_name ) : local.drg_options_defaults.display_name
  route_table_id        = var.drg_options != null ? ( var.drg_options.route_table_id != null ? var.drg_options.route_table_id : local.drg_options_defaults.route_table_id ) : local.drg_options_defaults.route_table_id
}


######################
# Routing policies
######################
# default values
locals {
  route_table_defaults  = {
    display_name        = "unnamed"
    compartment_id      = null
    route_rules         = []
  }
}

# resource definitions
resource "oci_core_route_table" "this" {
  count                 = length(var.route_tables)
  compartment_id        = var.route_tables[keys(var.route_tables)[count.index]].compartment_id != null ? var.route_tables[keys(var.route_tables)[count.index]].compartment_id : var.default_compartment_id
  vcn_id                = var.vcn_options != null ? oci_core_vcn.this[0].id : var.existing_vcn_id
  display_name          = keys(var.route_tables)[count.index] != null ? keys(var.route_tables)[count.index] : "${local.route_table_defaults.display_name}-${count.index}"
  defined_tags          = var.route_tables[keys(var.route_tables)[count.index]].defined_tags != null ? var.route_tables[keys(var.route_tables)[count.index]].defined_tags : var.default_defined_tags
  freeform_tags         = var.route_tables[keys(var.route_tables)[count.index]].freeform_tags != null ? var.route_tables[keys(var.route_tables)[count.index]].freeform_tags : var.default_freeform_tags
  
  # iterate through all defined route rules (if they exist) and populate blocks for each one...
  dynamic "route_rules" {
    iterator            = rule
    for_each            = var.route_tables[keys(var.route_tables)[count.index]].route_rules
    
    content {
      network_entity_id = rule.value.next_hop_id
      destination       = rule.value.dst
      destination_type  = rule.value.dst_type
    }
  }
}

######################
# DNS policies
######################
# default values
locals {
  dhcp_options_defaults = {
    display_name        = "unnamed"
    compartment_id      = null
    server_type         = "VcnLocalPlusInternet"
    search_domain_name  = local.vcn_with_dns ? ( oci_core_vcn.this[0] != null ? "${oci_core_vcn.this[0].dns_label}.oraclevcn.com" : null ) : null
    forwarder_1_ip      = null
    forwarder_2_ip      = null
    forwarder_3_ip      = null
  }
}

# resource definitions
resource "oci_core_dhcp_options" "this" {
  count                 = length(keys(var.dhcp_options))
  compartment_id        = var.dhcp_options[keys(var.dhcp_options)[count.index]].compartment_id != null ? var.dhcp_options[keys(var.dhcp_options)[count.index]].compartment_id : var.default_compartment_id
  vcn_id                = var.vcn_options != null ? oci_core_vcn.this[0].id : var.existing_vcn_id
  display_name          = keys(var.dhcp_options)[count.index] != null ? keys(var.dhcp_options)[count.index] : "${local.dhcp_options_defaults.display_name}-${count.index}"
  
  dynamic "options" {
    iterator            = item
    for_each            = [
      for x in var.dhcp_options[keys(var.dhcp_options)[count.index]].search_domain_name != null ? [var.dhcp_options[keys(var.dhcp_options)[count.index]]] : [local.dhcp_options_defaults] :
        {
          search_domain_name : x.search_domain_name
        } if x.search_domain_name != null
    ]
    
    content {
      type                = "SearchDomain"
      search_domain_names = [ item.value.search_domain_name ]
    }
  }

  # dynamic block to handle custom/vcn options
  dynamic "options" {
    iterator            = item
    for_each            = [
      for x in var.dhcp_options[keys(var.dhcp_options)[count.index]].server_type != null ? [var.dhcp_options[keys(var.dhcp_options)[count.index]]] : [local.dhcp_options_defaults] :
        {
          server_type : x.server_type
        } if x.server_type == "VcnLocalPlusInternet"
    ]
    
    content {
      type              = "DomainNameServer"
      server_type       = item.value.server_type
    }
  }

  dynamic "options" {
    iterator            = item
    for_each            = [
      for x in var.dhcp_options[keys(var.dhcp_options)[count.index]].server_type != null ? [var.dhcp_options[keys(var.dhcp_options)[count.index]]] : [local.dhcp_options_defaults] :
        {
          server_type : x.server_type
          forwarders  : [
            for x in list(x.forwarder_1_ip, x.forwarder_2_ip, x.forwarder_3_ip):
              x if x != null
          ]
        } if x.server_type == "CustomDnsServer"
    ]
    
    content {
      type                = "DomainNameServer"
      server_type         = item.value.server_type
      custom_dns_servers  = item.value.forwarders
    }
  }
}
