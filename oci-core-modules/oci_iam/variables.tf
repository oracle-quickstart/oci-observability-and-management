# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# iam configuration
variable "iam_config" {
  type = object({
    default_compartment_id = string,
    default_defined_tags   = map(string),
    default_freeform_tags  = map(string),
    compartments = map(object({
      description    = string,
      compartment_id = string,
      defined_tags   = map(string),
      freeform_tags  = map(string)
    }))
    groups = map(object({
      compartment_id = string,
      defined_tags   = map(string),
      freeform_tags  = map(string),
      description    = string
    })),
    users = map(object({
      compartment_id = string,
      defined_tags   = map(string),
      freeform_tags  = map(string),
      description    = string,
      email          = string,
      groups         = list(string)
    })),
    dynamic_groups = map(object({
      compartment_id = string,
      description    = string,
      matching_rules = list(string),
      defined_tags   = map(string),
      freeform_tags  = map(string)
    })),
    policies = map(object({
      compartment_id = string,
      defined_tags   = map(string),
      freeform_tags  = map(string),
      description    = string,
      statements     = list(string),
      version_date   = string
      })
    )
  })
  description = "Parameters to provision zero, one or multiple dynamic groups"
}



