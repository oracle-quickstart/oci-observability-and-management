# Oracle Cloud Infrastructure (OCI) Subnet Module for Terraform

## Introduction

This module provides a way to provision a Subnet(s) and set the related configuration options in Oracle Cloud Infrastructure (OCI). This serves as a foundational component in an OCI environment.

## Solution

Subnets are the home for many IP-based resources in OCI. Much like a VLAN in traditional on-prem LANs.

| Resource | Created by Default? |
|---|---|
| Subnet(s) | No |

### Prerequisites
This module does not create any dependencies or prerequisites (these must be created prior to using this module):

* VCN
* Security List(s)
  * The *network_security* module may be used to create and manage Security Lists.
* Route Table
  * Often times only a couple of routing policies exist and are created in the *network* module.
* DHCP Options
  * Often times only a couple of DHCP Options (DNS profiles) exist and are created in the *network* module.


## Getting Started

Several fully-functional examples have been provided in the `examples` directory. Refer to the README.md in each example directory for directions specific to each example.

To get started quickly, for the minimum deployment, you can use the following example:

```
module "oci_subnets" {
  source          = "https://github.com/oracle-terraform-modules/terraform-oci-tdf-subnet.git"
  
  default_compartment_id  = var.default_compartment_id
  vcn_id                  = oci_core_vcn.this.id
  vcn_cidr                = oci_core_vcn.this.cidr_block
  
  subnets = {}
}
```

This will deploy a Subnet using the module defaults. Review this README for a detailed description of these parameters.

## Accessing the Solution

This core service module is typically used at deployment, with no further access required; you might need to access a bastion, if it's been requested to be created as a part of the solution.

You may continue to manage the deployed environment using Terraform (best), the OCI CLI, the OCI console (UI), directly via the API, etc.


## Resource-specific inputs

### Provider

The following IAM attributes are available in the the `terraform.tfvars` file:

```
### PRIMARY TENANCY DETAILS

# Get this from the bottom of the OCI screen (after logging in, after Tenancy ID: heading)
primary_tenancy_id="<tenancy OCID"
# Get this from OCI > Identity > Users (for your user account)
primary_user_id="<user OCID>"

# the fingerprint can be gathered from your user account (OCI > Identity > Users > click your username > API Keys fingerprint (select it, copy it and paste it below))
primary_fingerprint="<PEM key fingerprint>"
# this is the full path on your local system to the private key used for the API key pair
primary_private_key_path="<path to the private key that matches the fingerprint above>"

# region (us-phoenix-1, ca-toronto-1, etc)
primary_region="<your region>"

### DR TENANCY DETAILS

# Get this from the bottom of the OCI screen (after logging in, after Tenancy ID: heading)
dr_tenancy_id="<tenancy OCID"
# Get this from OCI > Identity > Users (for your user account)
dr_user_id="<user OCID>"

# the fingerprint can be gathered from your user account (OCI > Identity > Users > click your username > API Keys fingerprint (select it, copy it and paste it below))
dr_fingerprint="<PEM key fingerprint>"
# this is the full path on your local system to the private key used for the API key pair
dr_private_key_path="<path to the private key that matches the fingerprint above>"

# region (us-phoenix-1, ca-toronto-1, etc)
dr_region="<your region>"
```

### Subnet

The Subnet input variable represents a map of attributes.
The automation creates the following resources with the following attributes:

| Attribute | Data Type | Required | Default Value | Valid Values | Description |
|---|---|---|---|---|---|
| default\_compartment\_id | string | yes | none | string of the compartment OCID | This is the default OCID that will be used when creating objects (unless overridden for any specific object).  This needs to be the OCID of a pre-existing compartment (it will not create the compartment. |
| vcn\_id | string | yes | N/A (no default) | VCN OCID | The OCID of the VCN in which the subnet(s) are to be created. |
| vcn\_cidr | string | no | N/A (no default) | CIDR | The CIDR used by the VCN. This is only needed when dynamically generating subnet CIDRs.
| define\_tags | map(string) | no | N/A (no default) | The defined tags
| freeform\_tags| map(string) | no | N/A (no default) | The freeform\_tags


**`subnets`**


Each entry's key specifies the name to be given to the subnet, with its attributes specified as values in a sub-map.

| Key | Data Type | Default Value | Valid Values | Description |
|---|---|---|---|---|
| compartment\_id | string | null | Compartment OCID | Pre-existing compartment OCID (if default compartment is not to be used).  If this value is null, the default compartment OCID will be used. |
| define\_tags | map(string) | no | N/A (no default) | The defined tags
| freeform\_tags| map(string) | no | N/A (no default) | The freeform\_tags
| dynamic_cidr | bool | false | true/false | Whether or not the CIDR should be dynamically calculated (true) or statically set (false). |
| cidr | string | static cidr: null, dynamic_cidr: VCN CIDR | IPv4 CIDR | If dynamic_cidr is true, the CIDR specified here will be used in the subnet calculation.  If dynamic_cidr is false, the CIDR specified here will be the one used by the subnet. |
| cidr\_len | number | 28 | Any number between 16 and 30 | Number of bits in the subnet mask. Only applicable if dynamic_cidr is true. |
| cidr\_num | number | Defaults to the index number of the subnet being defined | number | zero-indexed network number use for the subnet.  For example,  192.168.0.0/16 and cidr\_len is 24.  For cidr\_num of 1, a dynamically generated CIDR of 192.168.1.0/24 would be given.  A cidr\_num of 0, 192.168.0.0/24 would result and cidr\_num of 240 would yield 192.168.240.0/24. |
| enable\_dns | bool | true | true/false | Whether or not DNS should be enabled for the subnet. |
| dns\_label | string | "vcn" | Valid DNS name. | Specify the DNS label to be used for the VCN.  If this value is null, a dynamically generated value of *subnet<index_num>* will be used.  For example, the third subnet definition, if DNS is enabled, but no dns_label is provided (a null value is given), a value of *subnet2* will be generated (remembering that index numbers are zero-indexed). |
| private | bool | true | true/false | If set to true, the subnet will be a private subnet.  If set to false, a public subnet will be created. |
| ad | number | null | null, 0, 1 or 2 (dependent upon the number of available Availability Domains (ADs)| For a regional subnet value should be set to null. Number (zero-index, meaning AD1 = 0, AD2 = 1, AD3 = 2) to create an AD-specific subnet. |
| dhcp\_options\_id | string | null | null or OCID | Specify the OCID of the DHCP Options to use for the subnet. |
| route\_table\_id | string | null | null or OCID | Specify the OCID of the Route Table to use for the subnet. |
| security\_list\_ids | list of strings | null | null or list of OCID(s) | Specify the OCID(s) of the Security List(s) to use for the subnet, in list form. |

***Example***
The following example creates two subnets, *test1* and *test2*. 

```
module "oci_subnets" {
  ... /snip - shortened for brevity...

  default_compartment_id  = var.default_compartment_id
  # vcn_id = data.terraform_remote_state.network.outputs.vcn.id
  vcn_id                  = oci_core_vcn.this.id
  vcn_cidr                = oci_core_vcn.this.cidr_block
  
  subnets = {
    test1 = {
      compartment_id    = null
      defined_tags      = null
      freeform_tags     = null
      dynamic_cidr      = false
      cidr              = "192.168.0.0/30"
      cidr_len          = null
      cidr_num          = null
      enable_dns        = true
      dns_label         = "test1"
      private           = true
      ad                = null
      dhcp_options_id   = null
      route_table_id    = null
      security_list_ids = null
    },
    test2 = {
      compartment_id    = null
      defined_tags      = null
      freeform_tags     = null
      dynamic_cidr      = false
      cidr              = "192.168.0.4/30"
      cidr_len          = null
      cidr_num          = null
      enable_dns        = true
      dns_label         = "test2"
      private           = true
      ad                = 0
      dhcp_options_id   = null
      route_table_id    = null
      security_list_ids = null
    }
  }
}
```



## Outputs

A map containing each subnet is returned in the *subnets* output. The outer map key is the name of the subnet, with all subnet attributes (as a map) being returned as the value.

## Notes/Issues

* Note that if you provide any single element in the different resource maps (`subnets`), you must provide all of them.  Maps do not have a notion of an optional (or default value) for keys within the map, requiring that all keys/values be passed (if one key is passed, all keys must be passed).

## Release Notes

See [release notes](./docs/release_notes.md) for release notes information.

## URLs
* [https://www.terraform.io/docs/providers/oci/r/core_subnet.html](https://www.terraform.io/docs/providers/oci/r/core_subnet.html)

## Contributing

This project is open source. Oracle appreciates any contributions that are made by the open source community.

## License

Copyright (c) 2020 Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

See [LICENSE](LICENSE) for more details.
