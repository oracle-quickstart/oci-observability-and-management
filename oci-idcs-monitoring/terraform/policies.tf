## Copyright (c) 2021, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "oci_identity_compartment" "vault_compartment" {
  id = var.idcs_cred_vault_compartment
}

# Functions Policies

# Removed "Allow service objectstorage-${var.region} to manage object-family in tenancy",
# Removed "allow dynamic-group ${oci_identity_dynamic_group.FunctionsServiceDynamicGroup[0].name} to read loganalytics-resources-family in tenancy"
resource "oci_identity_policy" "IDCSFunctionsPolicy" {
  provider = oci.homeregion
  depends_on     = [oci_identity_dynamic_group.FunctionsServiceDynamicGroup]
  name = "IDCSFunctionPolicy-${local.compartment_name}-${random_id.tag.hex}"
  description = "IDCSFunctionPolicy"
  compartment_id = var.tenancy_ocid
  count = var.setup_policies ? 1 : 0
  statements = ["Allow service FaaS to read repos in tenancy", 
        "Allow service FaaS to use virtual-network-family in compartment id ${var.compartment_ocid}",
        "Allow service loganalytics to manage object-family in tenancy", "allow service loganalytics to inspect compartments in tenancy", 
        "Allow service loganalytics to use tag-namespaces in tenancy where all {target.tag-namespace.name = /oracle-tags/}",
        "Allow dynamic-group ${oci_identity_dynamic_group.FunctionsServiceDynamicGroup[0].name} to manage all-resources in compartment id ${var.compartment_ocid}", 
        "Allow dynamic-group ${oci_identity_dynamic_group.FunctionsServiceDynamicGroup[0].name} to use loganalytics-ondemand-upload in tenancy", 
        "Allow dynamic-group ${oci_identity_dynamic_group.FunctionsServiceDynamicGroup[0].name} to {LOG_ANALYTICS_LOG_GROUP_UPLOAD_LOGS, LOG_ANALYTICS_ENTITY_UPLOAD_LOGS, LOG_ANALYTICS_SOURCE_READ} in tenancy", 
        "Allow any-user to use functions-family in compartment id ${var.compartment_ocid} where ALL {request.principal.type= 'ApiGateway', request.resource.compartment.id = '${var.compartment_ocid}'}",
        "Allow dynamic-group ${oci_identity_dynamic_group.FunctionsServiceDynamicGroup[0].name} to read secret-family in compartment id ${var.idcs_cred_vault_compartment}"]

  provisioner "local-exec" {
       command = "sleep 5"
  }
}

resource "oci_identity_dynamic_group" "FunctionsServiceDynamicGroup" {
  provider = oci.homeregion
  name           = "FunctionsServiceDynamicGroup-${local.compartment_name}-${random_id.tag.hex}"
  description    = "FunctionsServiceDynamicGroup"
  compartment_id = var.tenancy_ocid
  count = var.setup_policies ? 1 : 0
  matching_rule  = "ALL {resource.type = 'fnfunc', resource.compartment.id = '${var.compartment_ocid}'}"

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

#resource "oci_identity_policy" "FunctionsDynamicGroupPolicy" {
#  provider       = oci.homeregion
#  depends_on     = [oci_identity_dynamic_group.FunctionsServiceDynamicGroup]
#  name           = "FunctionsDynamicGroupPolicy"
#  description    = "FunctionsDynamicGroupPolicy"
#  compartment_id = var.tenancy_ocid
#  statements     = ["allow dynamic-group ${oci_identity_dynamic_group.FunctionsServiceDynamicGroup.name} to manage all-resources in compartment id ${var.compartment_ocid}", "allow dynamic-group ${oci_identity_dynamic_group.FunctionsServiceDynamicGroup.name} to use loganalytics-ondemand-upload in tenancy", "allow dynamic-group ${oci_identity_dynamic_group.FunctionsServiceDynamicGroup.name} to read loganalytics-resources-family in tenancy", "allow dynamic-group ${oci_identity_dynamic_group.FunctionsServiceDynamicGroup.name} to {LOG_ANALYTICS_LOG_GROUP_UPLOAD_LOGS, LOG_ANALYTICS_ENTITY_UPLOAD_LOGS, LOG_ANALYTICS_SOURCE_READ} in tenancy"]
#
#  provisioner "local-exec" {
#    command = "sleep 5"
#  }
#}
