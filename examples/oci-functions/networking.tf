locals {
  vcn_display_name           = "${var.resource_name_prefix}-vcn"
  internet_gateway_name      = "${var.resource_name_prefix}-igw"
  public_route_table_name    = "${var.resource_name_prefix}-rt-public"
  public_security_list_name  = "${var.resource_name_prefix}-sl-public"
  public_subnet_display_name = "${var.resource_name_prefix}-subnet-public"
}

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  display_name   = local.vcn_display_name
  dns_label      = "fnvcn"
  defined_tags   = var.defined_tags
  freeform_tags  = var.freeform_tags
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = local.internet_gateway_name
  enabled        = true
  defined_tags   = var.defined_tags
  freeform_tags  = var.freeform_tags
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = local.public_route_table_name
  defined_tags   = var.defined_tags
  freeform_tags  = var.freeform_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this.id
  }
}

resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = local.public_security_list_name
  defined_tags   = var.defined_tags
  freeform_tags  = var.freeform_tags

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.public_subnet_cidr
  display_name               = local.public_subnet_display_name
  dns_label                  = "fnsubnet"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.public.id]
  defined_tags               = var.defined_tags
  freeform_tags              = var.freeform_tags
}
