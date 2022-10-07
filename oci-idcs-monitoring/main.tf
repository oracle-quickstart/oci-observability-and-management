## Copyright (c) 2022, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "null_resource" "Login2OCIR" {
  depends_on = [module.setup-network, oci_functions_application.IdcsAuditLogApp,
    oci_objectstorage_bucket.tracker-bucket, oci_identity_policy.IDCSFunctionsPolicy]

  provisioner "local-exec" {
    command = "echo '${var.ocir_user_password}' |  docker login ${local.ocir_docker_repository} --username ${local.namespace}/${var.ocir_user_name} --password-stdin"
  }
}

resource "null_resource" "IdcsAuditLogPush2OCIR" {
  depends_on = [null_resource.Login2OCIR, oci_functions_application.IdcsAuditLogApp]

  provisioner "local-exec" {
    command     = "image=$(docker images | grep postauditlogs | awk -F ' ' '{print $3}') ; docker rmi -f $image &> /dev/null ; echo $image"
    working_dir = "function/postauditlogs"
  }

  provisioner "local-exec" {
    command     = "fn build --verbose"
    working_dir = "function/postauditlogs"
  }

  provisioner "local-exec" {
    command     = "image=$(docker images | grep postauditlogs | awk -F ' ' '{print $3}') ; docker tag $image ${local.ocir_docker_repository}/${local.namespace}/${var.ocir_repo_name}/postauditlogs:0.0.1"
    working_dir = "function/postauditlogs"
  }

  provisioner "local-exec" {
    command     = "docker push ${local.ocir_docker_repository}/${local.namespace}/${var.ocir_repo_name}/postauditlogs:0.0.1"
    working_dir = "function/postauditlogs"
  }
}

module "setup-network" {
  source = "./modules/network"
  count  = var.create_network ? 1 : 0
  compartment_ocid = var.compartment_ocid
  VCN-CIDR = var.VCN-CIDR
  fnsubnet-CIDR = var.fnsubnet-CIDR
}

module "create-schedule" {
  source = "./modules/schedule"
  compartment_ocid = var.compartment_ocid
  subnet_ocid = var.create_network ? module.setup-network[0].fnsubnet_ocid : var.subnet_ocid
  function_id = oci_functions_function.postauditlogs.id 
  healthcheck_name = "IdcsAuditLogMonitor-${var.deployment_name}-${random_id.tag.hex}"
  gateway_name = "FunctionAPIGateway-${random_id.tag.hex}"
  pathprefix = "/fn"
  gateway_deployment_name = "IdcsLogFnEndpoint-${var.deployment_name}"
  path = "/postauditlogs-${var.deployment_name}"
  interval = 300
  timeout = 60
  log_group_id = oci_logging_log_group.log_group.id
  access_log_name = "IdcsApiGateway-access"
  exec_log_name = "IdcsApiGateway-exec"
}
