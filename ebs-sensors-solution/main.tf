# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  namespace                    = data.oci_objectstorage_namespace.os_namespace.namespace
  timestamp                    = formatdate("YYYYMMDDhhmmss", timestamp())
  instance_dynamic_group_name  = "Mgmtagent_Compute_Dynamicgroup_${local.timestamp}"
  instance_policy_name         = "Mgmtagent_Compute_Policies_${local.timestamp}"
  instance_tenancy_policy_name = "Mgmtagent_Tenancy_Policies_${local.timestamp}"
  mgmtagent_dynamic_group_name = "Mgmtagent_Dynamicgroup_${local.timestamp}"
  mgmtagent_policy_name        = "Mgmtagent_Policies_${local.timestamp}"
  db_name                      = "${var.la_entity_name}"
  log_group_name               = "EBSDBLogs"
}

# Compute instance dynamic group and policies
module "create_instance_dynamicgroup" {
  source = "./modules/identity"

  count = var.setup_policies ? 1 : 0

  providers = {
    oci = oci.home
  }

  tenancy_ocid              = var.tenancy_ocid
  dynamic_group_name        = local.instance_dynamic_group_name
  dynamic_group_description = "This is the compute instance dynamic group created by Agent stack"
  matching_rule             = "ANY {instance.compartment.id = '${var.db_compartment}'}"

  create_policies       = false
  policy_name           = local.instance_policy_name
  policy_description    = "This policy allows compute instances to manage Management agents"
  policy_compartment_id = var.db_compartment
  policy_statements = [
    "ALLOW DYNAMIC-GROUP ${local.instance_dynamic_group_name} TO MANAGE management-agents IN COMPARTMENT ID ${var.db_compartment}",
    "ALLOW DYNAMIC-GROUP ${local.instance_dynamic_group_name} TO READ secret-family in COMPARTMENT ID ${var.db_cred_compartment} where target.secret.id = '${var.db_credentials}'"
  ]
}

# Create policies for compute dynamic group at tenancy level
module "instance_tenancy_policies" {

  depends_on = [
    module.create_instance_dynamicgroup, module.create_mgmtagent_dynamicgroup
  ]

  source = "./modules/identity"

  count = var.setup_policies ? 1 : 0

  providers = {
    oci = oci.home
  }
  create_dynamicgroup   = false
  policy_name           = local.instance_tenancy_policy_name
  policy_description    = "These polices allow compute instances to install and configure mgmt agent and Agents to upload logs to Log Analytics"
  policy_compartment_id = var.tenancy_ocid
  policy_statements = [
    "Allow DYNAMIC-GROUP ${local.mgmtagent_dynamic_group_name} to {LOG_ANALYTICS_LOG_GROUP_UPLOAD_LOGS} in tenancy",
    "ALLOW DYNAMIC-GROUP ${local.mgmtagent_dynamic_group_name} TO MANAGE management-agents IN COMPARTMENT ID ${var.db_compartment}",
    "ALLOW DYNAMIC-GROUP ${local.mgmtagent_dynamic_group_name} TO USE METRICS IN COMPARTMENT ID ${var.db_compartment}",
    "ALLOW DYNAMIC-GROUP ${local.instance_dynamic_group_name} TO MANAGE management-agents IN COMPARTMENT ID ${var.db_compartment}",
  #  "ALLOW DYNAMIC-GROUP ${local.instance_dynamic_group_name} TO MANAGE management-agent-install-keys IN COMPARTMENT ID ${var.db_compartment}",
    "ALLOW DYNAMIC-GROUP ${local.instance_dynamic_group_name} TO MANAGE OBJECTS IN COMPARTMENT ID ${var.db_compartment}",
    "ALLOW DYNAMIC-GROUP ${local.instance_dynamic_group_name} TO READ BUCKETS IN COMPARTMENT ID ${var.db_compartment}",
    "ALLOW DYNAMIC-GROUP ${local.instance_dynamic_group_name} TO READ secret-family in COMPARTMENT ID ${var.db_cred_compartment} where target.secret.id = '${var.db_credentials}'"
  ]

}

# Management agent dynamic group and policies
module "create_mgmtagent_dynamicgroup" {
  source = "./modules/identity"

  count = var.setup_policies ? 1 : 0

  providers = {
    oci = oci.home
  }

  tenancy_ocid              = var.tenancy_ocid
  dynamic_group_name        = local.mgmtagent_dynamic_group_name
  dynamic_group_description = "This is a Management Agent dynamic group created by Agent stack"
  matching_rule             = "ALL {resource.type='managementagent', resource.compartment.id='${var.db_compartment}'}"

  create_policies       = false
  policy_name           = local.mgmtagent_policy_name
  policy_description    = "These are the required policies for Management Agent functionality"
  policy_compartment_id = var.db_compartment
  policy_statements = [
    "ALLOW DYNAMIC-GROUP ${local.mgmtagent_dynamic_group_name} TO MANAGE management-agents IN COMPARTMENT ID ${var.db_compartment}",
    "ALLOW DYNAMIC-GROUP ${local.mgmtagent_dynamic_group_name} TO USE METRICS IN COMPARTMENT ID ${var.db_compartment}"
  ]
}

module "create_compute_instance" {

  depends_on = [
    module.create_mgmtagent_dynamicgroup, module.create_instance_dynamicgroup, module.instance_tenancy_policies
  ]

  source = "./modules/core_compute"

  tenancy_id          = var.tenancy_ocid
  compartment_ocid    = var.db_compartment
  availability_domain = var.availability_domain
  display_name        = var.instance_name
  compute_shape       = var.instance_shape
  subnet_id           = var.subnet_ocid
  public_key          = var.user_ssh_secret
  db_secret_ocid      = var.db_credentials
  db_user             = var.db_username
  db_name             = local.db_name
  namespace           = local.namespace
  log_group_ocid      = var.create_log_group? oci_log_analytics_log_analytics_log_group.test_log_group[0].id : var.log_group_ocid
  bucket_name         = var.bucket_name
  file_name           = var.file_name
}

# This creates a 3 minutes delay that is required in further execution
module "wait_until_agent_is_ready" {
  depends_on = [
    module.create_compute_instance
  ]

  source          = "./modules/time_delay"
  wait_in_minutes = 3
}

module "macs_interactions" {
  # Wait for some time as agent creation might take time and might not be available immediately
  depends_on = [
    module.create_compute_instance,
    module.wait_until_agent_is_ready
  ]

  source = "./modules/macs"

  instance_ocid    = module.create_compute_instance.host_details.id
  compartment_ocid = var.db_compartment
}


# Creates Log Analytics entity
module "la_entity" {

  depends_on = [
    module.macs_interactions
  ]

  source = "./modules/logan_entity"

  compartment_id      = var.resource_compartment
  namespace           = local.namespace
  entity_type_name    = "Oracle Database Instance"
  name                = local.db_name
  management_agent_id = module.macs_interactions.agent_details.id
  properties          = tomap({ "host_name" = "${var.db_host}", "db_port" = "${var.db_port}", "service_name" = "${var.db_service}" })
}

resource "oci_log_analytics_log_analytics_log_group" "test_log_group" {
  compartment_id = var.resource_compartment
  display_name = local.log_group_name
  count = var.create_log_group ? 1 : 0
  namespace = local.namespace
  description = "Group for RBS DB Logs"
}

module "logan_sources" {
  depends_on = [
      module.la_entity
  ]
  source = "./modules/logan_sources"
  auth_type = var.auth_type
  config_file_profile = var.config_file_profile
  namespace = local.namespace
  compartment_id = var.resource_compartment
  for_each = toset(split(",", var.products))
      path = format("%s/%s", "./contents/sources", each.value) 
}

resource "null_resource" "import_lookups" {
  
  provisioner "local-exec" {
    command = "python3 ./scripts/import_lookup.py -t Lookup -a ${var.auth_type} -p ${var.config_file_profile} -n \"EBS Functional Sensors\" -f ./contents/lookups/EBS_Lookup.csv"
  }
}

# This creates a 3 minutes delay that is required in further execution
module "wait_until_entity_is_ready" {
  depends_on = [
    module.la_entity
  ]

  source          = "./modules/time_delay"
  wait_in_minutes = 3
}

module "create_assoc" {
  depends_on = [
    module.wait_until_entity_is_ready, module.logan_sources
  ]
  source = "./modules/logan_associations"
  for_each = toset(split(",", var.products))
      auth_type = var.auth_type
      config_file_profile = var.config_file_profile
      entity_compartment_id = var.resource_compartment
      entity_id = module.la_entity.entity_id
      filepath = format("%s/%s", "./contents/sources", each.value)
      loggroup_id = var.create_log_group? oci_log_analytics_log_analytics_log_group.test_log_group[0].id : var.log_group_ocid
}

resource "oci_management_dashboard_management_dashboards_import" "multiple_dashboard_files" { 
  for_each = var.dashboard_files 
    import_details = templatefile(format("%s/%s/%s", path.root,"contents/dashboards", each.value), {"compartment_ocid" : "${var.resource_compartment}"})
}
