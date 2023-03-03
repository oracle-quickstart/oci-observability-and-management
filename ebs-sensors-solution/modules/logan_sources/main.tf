
resource "oci_log_analytics_log_analytics_import_custom_content" "test_sources" {
    namespace = var.namespace
    is_overwrite = false
    for_each = fileset("${var.path}", "*.zip")
        import_custom_content_file = "${var.path}/${each.value}"
}

resource "null_resource" "delete_sources" {

  triggers = {
    auth_type = var.auth_type
    profile_name = var.config_file_profile
    compartment_id = var.compartment_id
    path = format("%q", var.path)
  }

  provisioner "local-exec" {
    when = destroy
    command = "python ./scripts/delete_sources.py -a ${self.triggers.auth_type} -p ${self.triggers.profile_name} -c ${self.triggers.compartment_id} -f ${self.triggers.path}"
  }
}
