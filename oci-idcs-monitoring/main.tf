## Copyright (c) 2021, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "null_resource" "Login2OCIR" {
  depends_on = [oci_functions_application.IdcsAuditLogApp,
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
