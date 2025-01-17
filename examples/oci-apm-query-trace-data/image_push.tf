data "oci_identity_tenancy" "current_tenancy" {
    tenancy_id = var.tenancy_ocid
}

data "oci_identity_user" "current_user" {
    user_id = var.current_user_ocid
}

locals {
  user_description = "User used by function to upload image to ocir"
  user_name = "function_user"
  namespace = data.oci_identity_tenancy.current_tenancy.name
  ocir_user_email = data.oci_identity_user.current_user.email
}

# ### Repository in the Container Image Registry for the container images underpinning the function
resource "oci_artifacts_container_repository" "container_repository_for_function" {
  # note: repository = store for all images versions of a specific container image - so it included the function name
  compartment_id = var.compartment_ocid
  display_name   = "${local.ocir_repo_name}/${local.function_name}"
  is_immutable   = false
  is_public      = false
}

resource "null_resource" "Login2OCIR" {
  depends_on = [oci_artifacts_container_repository.container_repository_for_function]
  provisioner "local-exec" {
    command = "echo '${var.user_auth_token}' |  docker login ${local.ocir_docker_repository} --username ${local.namespace}/${local.ocir_user_email} --password-stdin"
  }
}

### build the function into a container image and push that image to the repository in the OCI Container Image Registry
resource "null_resource" "FnPush2OCIR" {
  depends_on = [null_resource.Login2OCIR, oci_artifacts_container_repository.container_repository_for_function] # remove function image (if it exists) from local container registry
  provisioner "local-exec" {
    command     = "image=$(docker images | grep ${local.function_name} | awk -F ' ' '{print $3}') ; docker rmi -f $image &> /dev/null ; echo $image"
    working_dir = "apm-trace-querier"
  }
  provisioner "local-exec" {
    command     = "docker build . -t ${local.ocir_docker_repository}/${local.namespace}/${local.ocir_repo_name}/${local.function_name}:0.0.1"
    working_dir = "apm-trace-querier"
  }
  provisioner "local-exec" {
    command     = "docker push ${local.ocir_docker_repository}/${local.namespace}/${local.ocir_repo_name}/${local.function_name}:0.0.1"
    working_dir = "apm-trace-querier"
  }
}