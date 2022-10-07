# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Get instance ocid
data "oci_management_agent_management_agents" "agent_deployed" {
  compartment_id       = var.compartment_ocid
  is_customer_deployed = false
  host_id              = var.instance_ocid
}

# Get available plugins
data "oci_management_agent_management_agent_plugins" "available_plugins" {
  compartment_id = var.compartment_ocid
}

locals {
  # logan_plugin_id = [ for i in data.oci_management_agent_management_agent_plugins.available_plugins.management_agent_plugins: i.id if i.name == "logan"][0]
  # agent_id        = data.oci_management_agent_management_agents.agent_deployed.management_agents[0].id
  updated_details = data.oci_management_agent_management_agents.agent_deployed.management_agents[0]
}

/*
# Deploy LOGAN plugin
resource "oci_management_agent_management_agent" "updated_agent" {
    managed_agent_id    = local.agent_id
    deploy_plugins_id   = [local.logan_plugin_id]
}
*/
