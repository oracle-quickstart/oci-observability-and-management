# Oracle Cloud Infrastructure Network Module for Terraform

## Introduction

This module provides the initial bootstrapping needed to provision a new Virtual Cloud Network (VCN) and other optional services in Oracle Cloud Infrastructure (OCI).

## Solution

A VCN is the core foundation of a network in OCI.  This module provides the ability to create the following resources:

| Resource | Created by Default? |
|---|---|
| VCN | No (optional) |
| Internet Gateway | No (optional) |
| NAT Gateway | No (optional) |
| Service Gateway | No (optional) |
| Dynamic Routing Gateway | No (optional) |
| Bastion | No (optional) |

By using this module, a basic cloud network will be created, including the basic foundational communication paths (for most use-cases, though not all). For situations where VPN-connect, FastConnect or VCN Peering is needed, these services will need to be built on top of the VCN deployed by this module.

## Getting Started

Several fully-functional examples has been provided in the `examples` directory.  Refer to the `README.md` in each example directory for directions specific to each example.

To get started quickly, for the minimum deployment, you can use the following example:

```
module "oci_network" {
  source           = "../../"
  #source          = "oracle-terraform-modules/default-vcn/oci"
  
  default_compartment_id = "${var.compartment_id}"
}
```

This will deploy a VCN using the module defaults. Review this README for a detailed description of these parameters.

## Accessing the Solution

This core service module is typically used at deployment, with no further access required; you might need to access a bastion, if it's been requested to be created as a part of the solution.

You may continue to manage the deployed environment using Terraform (best), the OCI CLI, the OCI console (UI), directly via the API, etc.


## Resource-specific inputs

### VCN

| Attribute | Data Type | Required | Default Value | Valid Values | Description |
|---|---|---|---|---|---|
| default\_compartment\_id | string | yes | none | string of the compartment OCID | This is the default OCID that will be used when creating objects (unless overridden for any specific object).  This needs to be the OCID of a pre-existing compartment (it will not create the compartment). |
| vcn\_options | map | no | see below | see below | The optional parameters that can be used to customize the VCN.  |
| existing\_vcn\_id | string | no | null | The OCID of any pre-existing VCN | If a new VCN is not to be created, then the OCID of an existing VCN should be provided here.  All created resources will be a part of this pre-existing VCN (if a VCN is not provided). |

Note that as the VCN is created, the default resources (Route Table, Security List and DHCP Options) are left as-is (not modified in any way).  Often these resources are not used.  See the documentation around [Default Resources](https://www.terraform.io/docs/providers/oci/guides/managing_default_resources.html), [Default Components that Come With Your VCN](https://docs.cloud.oracle.com/iaas/Content/Network/Concepts/overview.htm#default) and [Default Security Lists](https://docs.cloud.oracle.com/iaas/Content/Network/Concepts/securitylists.htm#default-list) for more information.

**`vcn_options`**

The `vcn_options` attribute is an optional map attribute.  Note that if this attribute is used, all keys/values must be specified (Terraform does not allow for default or optional map keys/values).  It has the following defined keys (and default values):

| Key | Data Type | Default Value | Valid Values | Description |
|---|---|---|---|---|
| display\_name | string | "vcn" | Any name acceptable to the OCI API. | Used to define a specific name for your VCN. |
| compartment\_id | string | null | Compartment OCID | Pre-existing compartment OCID (if default compartment is not to be used).  If this value is null, the default compartment OCID will be used. |
| defined\_tags | map(string) | {} | Any map of tag names and values that is acceptable to the OCI API. | If any Defined Tags should be set on this resource, do so with this attribute. |
| freeform\_tags | map(string) | {} | Any map of tag names and values that is acceptable to the OCI API. | If any Freeform Tags should be set on this resource, do so with this attribute. |
| cidr | string | "10.0.0.0/16" | IPv4 CIDR | Specify the IPv4 CIDR to be used for the VCN. |
| enable\_dns | bool | true | true/false | Whether or not DNS should be enabled on the VCN. |
| dns\_label | string | "vcn" | Valid DNS name. | Specify the DNS label to be used for the VCN.  If this value is null, DNS will be disabled for the VCN. |

***Example***

The following example creates VCN with a CIDR of 10.0.0.0/24, display name of *Module test*, DNS label of *testvcn* and use the default compartment OCID (not shown in the above example).

```
module "oci_network" {
  ... /snip - shortened for brevity...

  vcn_options = {
    display_name      = "Module test"
    cidr              = "10.0.0.0/24"
    enable_dns        = true
    dns_label         = "testvcn"
    compartment_id    = null
    defined_tags      = null
    freeform_tags     = null
  }
}
```


### Internet Gateway (IGW)

| Attribute | Data Type | Required | Default Value | Valid Values | Description |
|---|---|---|---|---|---|
| create\_igw | bool | no | false | true/false | Whether or not a IGW should be created in the VCN. |
| igw\_options | map | no | see below | see below | The optional parameters that can be used to customize the IGW. |

**`igw_options`**

The `igw_options` attribute is an optional map attribute.  Note that if this attribute is used, all keys/values must be specified (Terraform does not allow for default or optional map keys/values).  It has the following defined keys (and default values):

| Key | Data Type | Default Value | Valid Values | Description |
|---|---|---|---|---|
| display\_name | string | "igw" | Any name acceptable to the OCI API. | Used to define a specific name for your IGW. |
| compartment\_id | string | null | Compartment OCID | Pre-existing compartment OCID (if default compartment is not to be used).  If this value is null, the default compartment OCID will be used. |
| defined\_tags | map(string) | {} | Any map of tag names and values that is acceptable to the OCI API. | If any Defined Tags should be set on this resource, do so with this attribute. |
| freeform\_tags | map(string) | {} | Any map of tag names and values that is acceptable to the OCI API. | If any Freeform Tags should be set on this resource, do so with this attribute. |
| enabled | bool | true | true/false | Whether or not the IGW should be enabled. |

***Example***

```
module "oci_network" {
  ... /snip - shortened for brevity...

  igw_options = {
    display_name     = "my_igw"
    compartment_id   = null
    defined_tags     = null
    freeform_tags    = null
    enabled          = false
  }
}
```

The above example will create a IGW (enabled) in the VCN with a display name of *my_igw* and use the default compartment OCID (not shown in the above example).

### NAT Gateway (NATGW)

| Attribute | Data Type | Required | Default Value | Valid Values | Description |
|---|---|---|---|---|---|
| create\_natgw | bool | no | false | true/false | Whether or not a NATGW should be created in the VCN. |
| natgw\_options | map | no | see below | see below | The optional parameters that can be used to customize the NATGW. |

**`natgw_options`**

The `natgw_options` attribute is an optional map attribute.  Note that if this attribute is used, all keys/values must be specified (Terraform does not allow for default or optional map keys/values).  It has the following defined keys (and default values):

| Key | Data Type | Default Value | Valid Values | Description |
|---|---|---|---|---|
| display\_name | string | "natgw" | Any name acceptable to the OCI API. | Used to define a specific name for your IGW. |
| compartment\_id | string | null | Compartment OCID | Pre-existing compartment OCID (if default compartment is not to be used).  If this value is null, the default compartment OCID will be used. |
| defined\_tags | map(string) | {} | Any map of tag names and values that is acceptable to the OCI API. | If any Defined Tags should be set on this resource, do so with this attribute. |
| freeform\_tags | map(string) | {} | Any map of tag names and values that is acceptable to the OCI API. | If any Freeform Tags should be set on this resource, do so with this attribute. |
| block\_traffic | bool | false | true/false | Whether or not the NATGW should block traffic. |

***Example***

```
module "oci_network" {
  ... /snip - shortened for brevity...

  natgw_options = {
    display_name     = "my_natgw"
    compartment_id   = null
    defined_tags     = null
    freeform_tags    = null
    block_traffic    = false
  }
}
```

The above example will create a NATGW in the VCN with a display name of *my_natgw*, it will not block traffic and will use the default compartment OCID (not shown in the above example).

### Service Gateway (SVCGW)

| Attribute | Data Type | Required | Default Value | Valid Values | Description |
|---|---|---|---|---|---|
| create\_svcgw | bool | no | false | true/false | Whether or not a SVCGW should be created in the VCN. |
| svcgw\_options | map | no | see below | see below | The optional parameters that can be used to customize the SVCGW. |

**`svcgw_options`**

The `svcgw_options` attribute is an optional map attribute.  Note that if this attribute is used, all keys/values must be specified (Terraform does not allow for default or optional map keys/values).  It has the following defined keys (and default values):

| Key | Data Type | Default Value | Valid Values | Description |
|---|---|---|---|---|
| display\_name | string | "svcgw" | Any name acceptable to the OCI API. | Used to define a specific name for your SVCGW. |
| compartment\_id | string | null | Compartment OCID | Pre-existing compartment OCID (if default compartment is not to be used).  If this value is null, the default compartment OCID will be used. |
| defined\_tags | map(string) | {} | Any map of tag names and values that is acceptable to the OCI API. | If any Defined Tags should be set on this resource, do so with this attribute. |
| freeform\_tags | map(string) | {} | Any map of tag names and values that is acceptable to the OCI API. | If any Freeform Tags should be set on this resource, do so with this attribute. |
| services | list(string) | null | The OCID(s) of any valid OCI service gateway service(s). | Provide the service that should be permitted by the Service Gateway.  Use the `svcgw_services` module output for a list of services in the region (see below for an example of this). |

***Example***

```
module "oci_network" {
  ... /snip - shortened for brevity...

  svcgw_options = {
    display_name      = "my_svcgw"
    compartment_id    = null
    defined_tags      = null
    freeform_tags     = null
    services          = [
      module.oci_network.svcgw_services.0.id
    ]
  }
}
```

The above example will create a SVCGW in the VCN with a display name of *my_svcgw*, use the default compartment OCID (not shown in the above example) and will use the first service in the list of services available in the region.

### Dynamic Routing Gateway (DRG)

| Attribute | Data Type | Required | Default Value | Valid Values | Description |
|---|---|---|---|---|---|
| create\_drg | bool | no | false | true/false | Whether or not a DRG should be created in the VCN. |
| drg\_options | map | no | see below | see below | The optional parameters that can be used to customize the DRG. |

**`drg_options`**

The `drg_options` attribute is an optional map attribute.  Note that if this attribute is used, all keys/values must be specified (Terraform does not allow for default or optional map keys/values).  It has the following defined keys (and default values):

| Key | Data Type | Default Value | Valid Values | Description |
|---|---|---|---|---|
| display\_name | string | "drg" | Any name acceptable to the OCI API. | Used to define a specific name for your DRG. |
| compartment\_id | string | null | Compartment OCID | Pre-existing compartment OCID (if default compartment is not to be used).  If this value is null, the default compartment OCID will be used. |
| defined\_tags | map(string) | {} | Any map of tag names and values that is acceptable to the OCI API. | If any Defined Tags should be set on this resource, do so with this attribute. |
| freeform\_tags | map(string) | {} | Any map of tag names and values that is acceptable to the OCI API. | If any Freeform Tags should be set on this resource, do so with this attribute. |
| route\_table\_id | string | null | The OCID of any valid, pre-existing OCI Route Table. | This is optional, but in cases where a Route Table association is desired (with the DRG), it's the place to establish this association. |

***Example***

```
module "oci_network" {
  ... /snip - shortened for brevity...

  drg_options = {
    display_name     = "my_drg"
    compartment_id   = null
    defined_tags     = null
    freeform_tags    = null
    route_table_id   = null
  }
}
```

The above example will create a SVCGW in the VCN with a display name of *my_drg*, use the default compartment OCID (not shown in the above example) and will not associate any Route Table with the DRG.

### route\_tables

The `route_tables` attribute is an optional map attribute.  Note that if this attribute is used, all keys/values must be specified (Terraform does not allow for default or optional map keys/values).  The key indicates the display name for the route table, while the value is a map that defines the attributes.  The value is a map that has the following defined keys (and default values):

| Key | Data Type | Default Value | Valid Values | Description |
|---|---|---|---|---|
| compartment\_id | string | null | Compartment OCID | Pre-existing compartment OCID (if default compartment is not to be used).  If this value is null, the default compartment OCID will be used. |
| defined\_tags | map(string) | {} | Any map of tag names and values that is acceptable to the OCI API. | If any Defined Tags should be set on this resource, do so with this attribute. |
| freeform\_tags | map(string) | {} | Any map of tag names and values that is acceptable to the OCI API. | If any Freeform Tags should be set on this resource, do so with this attribute. |
| route\_rules | list(object) - see below | {} | See below | This is optional, but is the place where route rules are configured. |

**`route_rules`**

| Key | Data Type | Default Value | Valid Values | Description |
|---|---|---|---|---|
| next\_hop\_id | string | none | OCID of a next hop resource | This is where the next-hop is specified. |
| dst_type | string | none | *CIDR_BLOCK*, *SERVICE_CIDR_BLOCK* | Specify what kind of destination is being given in the *dst* attribute. |
| dst | string | none | A valid OCI destination (CIDR or Service CIDR). | Specify the destination (remote network) that is to be used for this route rule. |

***Example***

```
module "oci_network" {
  ... /snip - shortened for brevity...

  route_tables = {
    rt1 = {
      display_name     = "my_drg"
      compartment_id   = null
      defined_tags     = null
      freeform_tags    = null
      route_rules      = [
        {
          dst          = "0.0.0.0/0"
          dst_type     = "CIDR_BLOCK"
          next_hop_id  = local.next_hop_ids["igw"]
        }
      ]
    }
  }
}
```

The above example will create a Route Table in the VCN with a display name of *rt1* using the default compartment OCID (not shown in the above example), containing one route rule (pointing a default route to the Internet Gateway).

### dhcp\_options

The `dhcp_options` attribute is an optional map attribute.  Note that if this attribute is used, all keys/values must be specified (Terraform does not allow for default or optional map keys/values).  The key indicates the display name for the route table, while the value is a map that defines the attributes.  The value is a map that has the following defined keys (and default values):

| Key | Data Type | Default Value | Valid Values | Description |
|---|---|---|---|---|
| compartment\_id | string | null | Compartment OCID | Pre-existing compartment OCID (if default compartment is not to be used).  If this value is null, the default compartment OCID will be used. |
| server\_type | string | "VcnLocalPlusInternet" | *VcnLocalPlusInternet*, *CustomDnsServer* | One of the values permitted by the OCI API. | Specify the type of DHCP Option this is (custom or VCN+Internet). |
| search\_domain\_name | string | "${oci_core_vcn.this.dns_label}.oraclevcn.com" if local.vcn_with_dns is set, null otherwise | Provide a valid DNS name to be used. | This will be given as the domain to be searched. |
| forwarder\_1\_ip | string | null | Any valid IP address | This is used when a custom DNS server is specified. |
| forwarder\_2\_ip | string | null | Any valid IP address | This is used when a custom DNS server is specified. |
| forwarder\_3\_ip | string | null | Any valid IP address | This is used when a custom DNS server is specified. |

***Example***

```
module "oci_network" {
  ... /snip - shortened for brevity...

  dhcp_options            = {
    custom                = {
      compartment_id      = null
      server_type         = local.dhcp_option_types["custom"]
      forwarder_1_ip      = "10.0.0.11"
      forwarder_2_ip      = "10.0.2.11"
      forwarder_3_ip      = null
      search_domain_name  = "test.local"
    }
    vcn                   = {
      compartment_id      = null
      server_type         = local.dhcp_option_types["vcn"]
      forwarder_1_ip      = null
      forwarder_2_ip      = null
      forwarder_3_ip      = null
      search_domain_name  = null
    }
  }
}
```

The above example will create two DHCP Options, one named *custom*, which has two IP addresses used and references the custom DHCP Option type.  The *vcn* DHCP Option is pretty basic, just indicating that it should use VCNLocalPlusInternet and the name *vcn*.

## Outputs

Each discrete resource that's created by the module will be exported, allowing for access to all returned attributes for the resource.

| Resource | Always returned? | Description |
|---|---|---|
| ads | yes | The list of available ADs for the region you're working in. |
| vcn | no* | The VCN resource that has been created by the module. |
| igw | no* | The IGW resource created by the module (if it was requested/created). |
| natgw | no* | The NATGW resource created by the module (if it was requested/created). |
| svcgw | no* | The SVCGW resource created by the module (if it was requested/created). |
| svcgw\_services | yes | The services available that can be used. |
| drg | no* | The DRG and DRGAttachment resources created by the module (if it was requested/created).  Note that the DRG is accessible via drg.drg, and DRGAttachment via drg.drg_attachment. |
| route\_tables | no* | The Route Table(s) created/managed by the module (if it was requested/created).  A map is returned, where the key is the name of the Route Table and the value is a full listing of all of the resource attributes. |
| dhcp\_options | no* | The DHCP Options(s) created/managed by the module (if it was requested/created).  A map is returned, where the key is the name of the DHCP Option and the value is a full listing of all of the resource attributes. |

*only returned when the resource has been requested to be created.

Note that you may still reference the outputs (even if they're not returned) without causing an error in Terraform (it must be smart enough to know not to throw an error in these cases).


## Notes/Issues

* Note that if you provide any single element in the different resource maps (`vcn_options`, `igw_options`, etc), you must provide all of them.  Maps do not have a notion of an optional (or default value) for keys within the map, requiring that all keys/values be passed (if one key is passed, all keys must be passed).
* If you change certain parameters, TF will try to delete and create, however it doesn't work properly always... when you see errors like the below, use `terraform destroy`, then `terraform apply` (instead of relying on `terraform apply` to handle things correctly):

```
Error: Cycle: module.oci_network.oci_core_nat_gateway.this[0], module.oci_network.output.natgw, module.oci_network.oci_core_service_gateway.this[0], module.oci_network.output.svcgw, module.oci_network.oci_core_service_gateway.this[0] (destroy), module.oci_network.oci_core_nat_gateway.this[0] (destroy), module.oci_network.oci_core_vcn.this[0] (destroy), module.oci_network.oci_core_drg_attachment.this[0], module.oci_network.oci_core_route_table.this[1] (destroy), module.oci_network.oci_core_drg_attachment.this[0] (destroy), module.oci_network.output.drg, local.next_hop_ids, module.oci_network.var.route_tables, module.oci_network.oci_core_route_table.this (prepare state), module.oci_network.oci_core_route_table.this[0] (destroy), module.oci_network.oci_core_internet_gateway.this[0] (destroy), module.oci_network.oci_core_internet_gateway.this[0], module.oci_network.output.igw
```

## Release Notes

See [release notes](./docs/release_notes.md) for release notes information.

## URLs

* [https://www.terraform.io/docs/providers/oci/guides/managing_default_resources.html](https://www.terraform.io/docs/providers/oci/guides/managing_default_resources.html)
* [https://docs.cloud.oracle.com/iaas/Content/Network/Concepts/securitylists.htm#default-list](https://docs.cloud.oracle.com/iaas/Content/Network/Concepts/securitylists.htm#default-list)
* [https://docs.cloud.oracle.com/iaas/Content/Network/Concepts/overview.htm#default](https://docs.cloud.oracle.com/iaas/Content/Network/Concepts/overview.htm#default)

## Versions

This module has been developed and tested by running terraform on macOS Mojave Version 10.14.5

```
user-mac$ terraform --version
Terraform v0.12.3
+ provider.oci v3.31.0
```


## Contributing

This project is open source. Oracle appreciates any contributions that are made by the open source community.

## License

Copyright (c) 2020 Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

See [LICENSE](LICENSE) for more details.
