# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#########################
## ADs
#########################
output "ads" {
  description = "The Availability Domains (ADs) available in the region."
  value       = data.oci_identity_availability_domains.this.availability_domains
}

#########################
## VCN
#########################
output "vcn" {
  description = "The returned resource attributes for the VCN."
  value       = length(oci_core_vcn.this) > 0 ? oci_core_vcn.this[0] : null
}

#########################
## Internet Gateway
#########################

output "igw" {
  description = "Internet Gateway resource returned attributes."
  value       = length(oci_core_internet_gateway.this) >0 ? oci_core_internet_gateway.this[0] : null
}

#########################
## Service Gateway
#########################

output "svcgw" {
  description = "Service Gateway resource returned attributes."
  value       = length(oci_core_service_gateway.this) > 0 ? oci_core_service_gateway.this[0] : null
}

output "svcgw_services" {
  description = "Available services."
  value       = data.oci_core_services.this.*.services[0]
}

#########################
## NAT Gateway
#########################

output "natgw" {
  description = "NAT Gateway resource returned attributes."
  value       = length(oci_core_nat_gateway.this) > 0 ? oci_core_nat_gateway.this[0] : null
}

#########################
## Dynamic Routing Gateway
#########################

output "drg" {
  description = "DRG resource returned attributes."
  value = {
    drg            = length(oci_core_drg.this) > 0 ? oci_core_drg.this[0] : null
    drg_attachment = length(oci_core_drg_attachment.this) > 0 ?  oci_core_drg_attachment.this[0] : null
  }
}

#########################
## Route Tables
#########################

output "route_tables" {
  description = "A map of the Routing Tables that are created/managed in this module."
  value       = {
    for rt in oci_core_route_table.this:
      rt.display_name => rt
  }
}

#########################
## DHCP Options
#########################

output "dhcp_options" {
  description = "A map of the DHCP Options that are created/managed in this module."
  value       = {
    for items in oci_core_dhcp_options.this:
      items.display_name => items
  }
}
