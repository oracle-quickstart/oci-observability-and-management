# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


#########################
## IAM Config
#########################
output "iam_config" {
  description = "The returned resource attributes for the IAM configuration."
  #########################
  ## Compartments
  #########################
  value = {
    compartments = {
      for x in oci_identity_compartment.compartments : x.name => { name = x.name,
        description                                                     = x.description,
        compartment_id                                                  = x.compartment_id,
        defined_tags                                                    = x.defined_tags,
        freeform_tags                                                   = x.freeform_tags,
        id                                                              = x.id,
        is_accessible                                                   = x.is_accessible,
        state                                                           = x.state,
        time_created                                                    = x.time_created
      }
    },
    #########################
    ## Group and Users
    #########################
    groups_and_users = {
      groups = { for group in oci_identity_group.groups : group.name => {
        name           = group.name,
        compartment_id = group.compartment_id,
        defined_tags   = group.defined_tags,
        description    = group.description,
        freeform_tags  = group.freeform_tags,
        id             = group.id, state = group.state,
        time_created   = group.time_created
        }
      },
      users = { for user in oci_identity_user.users : user.name => {
        name           = user.name,
        capabilities   = user.capabilities,
        compartment_id = user.compartment_id,
        defined_tags   = user.defined_tags,
        description    = user.description,
        email          = user.email,
        freeform_tags  = user.freeform_tags,
        id             = user.id,
        state          = user.state,
        groups         = [for group_membership in oci_identity_user_group_membership.users_groups_membership : { "group_id" = group_membership.group_id, "group_name" = [for group in data.oci_identity_groups.groups.groups : group.name if group.id == group_membership.group_id][0] } if group_membership.user_id == user.id]
        }
      }
    },
    #########################
    ## Dynamic Groups
    #########################
    dynamic_groups = {
      for x in oci_identity_dynamic_group.dynamic_groups :
      x.name => { name = x.name,
        compartment_id = x.compartment_id
        defined_tags   = x.defined_tags
        description    = x.description
        freeform_tags  = x.freeform_tags
        id             = x.id
        matching_rule  = x.matching_rule
        state          = x.state
        time_created   = x.time_created
      }
    },
    #########################
    ## Policies
    #########################
    policies = {
      for x in oci_identity_policy.policies : x.name => { name = x.name,
        ETag                                                   = x.ETag,
        compartment_id                                         = x.compartment_id,
        defined_tags                                           = x.defined_tags,
        description                                            = x.description,
        freeform_tags                                          = x.freeform_tags,
        id                                                     = x.id,
        lastUpdateETag                                         = x.lastUpdateETag,
        policyHash                                             = x.policyHash,
        state                                                  = x.state,
        statements                                             = x.statements,
        time_created                                           = x.time_created,
        version_date                                           = x.version_date
      }
    }
  }
}


