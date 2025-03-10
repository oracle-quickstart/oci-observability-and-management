# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  next_hop_ids = {
    "igw" = module.oci_network.igw.id
  }
  anywhere            = "0.0.0.0/0"
  vcn_cidr            = "10.0.0.0/24"
  subnet_public_cidr  = cidrsubnet(local.vcn_cidr, 2, 0)
  subnet_private_cidr = cidrsubnet(local.vcn_cidr, 2, 1)
}

module "oci_network" {
  source                 = "../../oci-core-modules/oci_network"
  default_compartment_id = var.compartment_ocid

  vcn_options = {
    display_name   = "apm-data-exporter-vcn"
    cidr           = local.vcn_cidr
    enable_dns     = true
    dns_label      = "apmdataexporter"
    compartment_id = null
    defined_tags   = null
    freeform_tags  = null
  }

  svcgw_options = {
    display_name   = null
    compartment_id = null
    defined_tags   = null
    freeform_tags  = null
    services = [
      module.oci_network.svcgw_services.1.id
    ]
  }

  create_igw   = true
  create_svcgw = false
  create_natgw = false
  create_drg   = false

  route_tables = {

    igw = {
      compartment_id = null
      defined_tags   = null
      freeform_tags  = null
      route_rules = [
        {
          dst         = "0.0.0.0/0"
          dst_type    = "CIDR_BLOCK"
          next_hop_id = local.next_hop_ids["igw"]
        }
      ]
    }
  }

}

resource "oci_core_security_list" "sec_list" {
    compartment_id = var.compartment_ocid
    display_name = "securityList_test"
    vcn_id = module.oci_network.vcn.id
    
    egress_security_rules {
        protocol = "6"
        destination = "0.0.0.0/0"
    }
    
    dynamic "ingress_security_rules" {
    for_each = [80, 443]
    content {
        protocol = "6"
        source = "0.0.0.0/0"
        tcp_options {
            max = ingress_security_rules.value
            min = ingress_security_rules.value
            }
        }
    }

    ingress_security_rules {
        protocol = "6"
        source = "10.0.0.0/16"
    }
}

module "oci_subnets" {
  source = "../../oci-core-modules/oci_subnets"

  default_compartment_id = var.compartment_ocid
  vcn_id                 = module.oci_network.vcn.id
  vcn_cidr               = module.oci_network.vcn.cidr_block


  subnets = {
    public = {
      compartment_id    = null
      defined_tags      = null
      freeform_tags     = null
      dynamic_cidr      = false
      cidr              = local.subnet_public_cidr
      cidr_len          = null
      cidr_num          = null
      enable_dns        = null
      dns_label         = "public"
      private           = false
      ad                = null
      dhcp_options_id   = null
      route_table_id    = module.oci_network.route_tables.igw.id
      security_list_ids = [oci_core_security_list.sec_list.id]
    }
  }
}

