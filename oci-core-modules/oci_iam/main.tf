# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.



locals {

  #################
  # Compartments
  #################
  # default values

  default_compartment = {
    compartment_id = null
    description    = "OCI Compartment created with the OCI Core IAM Compartments Module"
    defined_tags   = {}
    freeform_tags  = { "Department" = "Security" }
  }

  #################
  # Group and users
  #################
  # default values

  default_group = {
    compartment_id = null
    description    = "OCI Identity Group created with the OCI Core IAM Users Groups Module"
    name           = "OCI-TF-Group"
    defined_tags   = {}
    freeform_tags  = { "Department" = "Security" }
  }

  #################
  # Users
  #################
  # default values

  default_user = {
    compartment_id = null
    description    = "OCI Identity User created with the OCI Core IAM Users Groups Module"
    name           = "OCI-TF-User"
    email          = null
    defined_tags   = {}
    freeform_tags  = { "Department" = "Security" }
  }

  #################
  # Dynamic Groups
  #################
  # default values

  default_dynamic_group = {
    compartment_id = null
    description    = "OCI Dynamic Group created with the OCI Core IAM Dymanic Groups Module"
    instance_ocids = []
    name           = "OCI-Dynamic-Group"
    defined_tags   = {}
    freeform_tags  = { "Department" = "Security" }
  }

  #################
  # Policy
  #################
  # default values

  default_policy = {
    tenancy_compartment_id = null
    description            = "OCI Policy created with the OCI Core IAM Policies Module"
    statements             = []
    name                   = "OCI-Policy"
    defined_tags           = {}
    freeform_tags          = { "Department" = "Security" }
    version_date           = formatdate("YYYY-MM-DD", timestamp())
  }


  keys_users = var.iam_config != null ? (var.iam_config.users != null ? keys(var.iam_config.users) : keys({})) : keys({})
  membership = var.iam_config != null ? distinct(flatten(var.iam_config.users != null ? [for user_name in local.keys_users : [for group_name in(var.iam_config.users[user_name].groups != null ? var.iam_config.users[user_name].groups : []) : [{ "user_name" = user_name, "group_name" = group_name }]]] : [])) : []
}

data "oci_identity_groups" "groups" {
  #Required
  provider       = oci.oci_home
  compartment_id = var.iam_config != null ? var.iam_config.default_compartment_id != null ? var.iam_config.default_compartment_id : local.default_group.compartment_id : "null"

  depends_on = [oci_identity_group.groups]
}

resource "oci_identity_compartment" "compartments" {
  provider = oci.oci_home
  for_each = var.iam_config != null ? (var.iam_config.compartments != null ? var.iam_config.compartments : {}) : {}

  #Required
  compartment_id = each.value.compartment_id != null ? each.value.compartment_id : (var.iam_config.default_compartment_id != null ? var.iam_config.default_compartment_id : local.default_compartment.compartment_id)
  description    = each.value.description != null ? each.value.description : local.default_compartment.description
  name           = each.key

  #Optional
  defined_tags  = each.value.defined_tags != null ? each.value.defined_tags : (var.iam_config.default_defined_tags != null ? var.iam_config.default_defined_tags : local.default_compartment.defined_tags)
  freeform_tags = each.value.freeform_tags != null ? each.value.freeform_tags : (var.iam_config.default_freeform_tags != null ? var.iam_config.default_freeform_tags : local.default_compartment.freeform_tags)
}

resource "oci_identity_group" "groups" {

  provider = oci.oci_home
  for_each = var.iam_config != null ? (var.iam_config.groups != null ? var.iam_config.groups : {}) : {}

  #Required
  compartment_id = each.value.compartment_id != null ? each.value.compartment_id : (var.iam_config.default_compartment_id != null ? var.iam_config.default_compartment_id : local.default_group.compartment_id)
  description    = each.value.description != null ? each.value.description : local.default_group.description
  name           = each.key

  #Optional
  defined_tags  = each.value.defined_tags != null ? each.value.defined_tags : (var.iam_config.default_defined_tags != null ? var.iam_config.default_defined_tags : local.default_group.defined_tags)
  freeform_tags = each.value.freeform_tags != null ? each.value.freeform_tags : (var.iam_config.default_freeform_tags != null ? var.iam_config.default_freeform_tags : local.default_group.freeform_tags)

  depends_on = [oci_identity_compartment.compartments]
}

resource "oci_identity_user" "users" {

  provider = oci.oci_home
  for_each = var.iam_config != null ? (var.iam_config.users != null ? var.iam_config.users : {}) : {}

  #Required
  compartment_id = each.value.compartment_id != null ? each.value.compartment_id : (var.iam_config.default_compartment_id != null ? var.iam_config.default_compartment_id : local.default_user.compartment_id)
  description    = each.value.description != null ? each.value.description : local.default_user.description
  name           = each.key

  #Optional
  defined_tags  = each.value.defined_tags != null ? each.value.defined_tags : (var.iam_config.default_defined_tags != null ? var.iam_config.default_defined_tags : local.default_user.defined_tags)
  email         = each.value.email != null ? each.value.email : local.default_user.email
  freeform_tags = each.value.freeform_tags != null ? each.value.freeform_tags : (var.iam_config.default_freeform_tags != null ? var.iam_config.default_freeform_tags : local.default_user.freeform_tags)

  depends_on = [oci_identity_group.groups]
}

resource "oci_identity_user_group_membership" "users_groups_membership" {
  count = var.iam_config != null ? (local.membership != null ? length(local.membership) : 0) : 0
  provider = oci.oci_home
  #Required
  group_id = contains([for group in data.oci_identity_groups.groups.groups : group.name], local.membership[count.index].group_name) == true ? [for group in data.oci_identity_groups.groups.groups : group.id if group.name == local.membership[count.index].group_name][0] : [for group in oci_identity_group.groups : group.id if group.name == local.membership[count.index].group_name][0]
  user_id  = [for user in oci_identity_user.users : user.id if user.name == local.membership[count.index].user_name][0]

  depends_on = [oci_identity_group.groups, oci_identity_user.users]
}

/* resource "oci_identity_dynamic_group" "dynamic_groups" {
  #provider = oci.oci_home
  for_each = var.iam_config != null ? (var.iam_config.dynamic_groups != null ? var.iam_config.dynamic_groups : {}) : {}
  #Required
  compartment_id = each.value.compartment_id != null ? each.value.compartment_id : (var.iam_config.default_compartment_id != null ? var.iam_config.default_compartment_id : local.default_dynamic_group.compartment_id)
  description    = each.value.description != null ? each.value.description : local.default_dynamic_group.description
  matching_rule  = length(each.value.instance_ids) > 0 ? "${format("%s %s %s", "any {", join(", ", formatlist("ALL {instance.id ='%s'}", each.value.instance_ids)), "}")}" : ""
  name           = each.key

  #Optional
  defined_tags  = each.value.defined_tags != null ? each.value.defined_tags : (var.iam_config.default_defined_tags != null ? var.iam_config.default_defined_tags : local.default_dynamic_group.defined_tags)
  freeform_tags = each.value.freeform_tags != null ? each.value.freeform_tags : (var.iam_config.default_freeform_tags != null ? var.iam_config.default_freeform_tags : local.default_dynamic_group.freeform_tags)

  depends_on = [oci_identity_compartment.compartments]
} */

resource "oci_identity_dynamic_group" "dynamic_groups" {
  #Required
  provider = oci.oci_home
  for_each       = var.iam_config != null ? (var.iam_config.dynamic_groups != null ? var.iam_config.dynamic_groups : {}) : {}
  compartment_id = each.value.compartment_id != null ? each.value.compartment_id : (var.iam_config.default_compartment_id != null ? var.iam_config.default_compartment_id : local.default_dynamic_group.compartment_id)
  description    = each.value.description != null ? each.value.description : local.default_dynamic_group.description
  //matching_rule = "All {resource.type = 'managementagent', resource.compartment.id = ${module.logging_analytics_compartment.iam_config.compartments["Logging-Analytics-Compartment"].id}}"
  // Note: We are setting rules for the logging analytics compartment, if you have defined Logging-Analytics-Agent-Compartment, then use that instead.  
  matching_rule = length(each.value.matching_rules) > 0 ? format("%s", join(",", each.value.matching_rules)) : ""
  name          = each.key
  #Optional
  defined_tags  = each.value.defined_tags != null ? each.value.defined_tags : (var.iam_config.default_defined_tags != null ? var.iam_config.default_defined_tags : local.default_dynamic_group.defined_tags)
  freeform_tags = each.value.freeform_tags != null ? each.value.freeform_tags : (var.iam_config.default_freeform_tags != null ? var.iam_config.default_freeform_tags : local.default_dynamic_group.freeform_tags)
  depends_on    = [oci_identity_compartment.compartments]
}

resource "oci_identity_policy" "policies" {
  provider = oci.oci_home
  for_each = var.iam_config != null ? (var.iam_config.policies != null ? var.iam_config.policies : {}) : {}
  #Required
  compartment_id = each.value.compartment_id != null ? each.value.compartment_id : (var.iam_config.default_compartment_id != null ? var.iam_config.default_compartment_id : local.default_policy.compartment_id)
  description    = each.value.description != null ? each.value.description : local.default_policy.description
  name           = each.key
  statements     = each.value.statements

  #Optional
  defined_tags  = each.value.defined_tags != null ? each.value.defined_tags : (var.iam_config.default_defined_tags != null ? var.iam_config.default_defined_tags : local.default_policy.defined_tags)
  freeform_tags = each.value.freeform_tags != null ? each.value.freeform_tags : (var.iam_config.default_freeform_tags != null ? var.iam_config.default_freeform_tags : local.default_policy.freeform_tags)
  version_date  = each.value.version_date != null ? each.value.version_date : local.default_policy.version_date

  depends_on = [oci_identity_dynamic_group.dynamic_groups, oci_identity_group.groups, oci_identity_user.users, oci_identity_compartment.compartments]
}

resource "oci_identity_domains_dynamic_resource_group" "dynamic_resource_group" {
    provider = oci.oci_home
    for_each = var.iam_config != null ? (var.iam_config.dynamic_groups_with_domain != null ? var.iam_config.dynamic_groups_with_domain : {}) : {}

    #Required
    display_name = each.key
    idcs_endpoint = each.value.identity_domain_url
    matching_rule = length(each.value.matching_rules) > 0 ? format("%s", join(",", each.value.matching_rules)) : ""
    schemas = ["urn:ietf:params:scim:schemas:oracle:idcs:DynamicResourceGroup"]
    description = each.value.description
}

resource "oci_identity_domains_group" "domains_group" {

    provider = oci.oci_home
    for_each = var.iam_config != null ? (var.iam_config.groups_with_domain != null ? var.iam_config.groups_with_domain : {}) : {}
    #Required
    display_name = each.key
    urnietfparamsscimschemasoracleidcsextensiongroup_group {
      description    = each.value.description != null ? each.value.description : local.default_group.description
    }
    idcs_endpoint = each.value.identity_domain_url
    schemas = ["urn:ietf:params:scim:schemas:core:2.0:Group"]    
}

