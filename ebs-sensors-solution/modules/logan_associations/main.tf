#locals {
#  current_time = timestamp()
#}

# Upsert or delete Associations
resource null_resource manage_assocs {
  triggers = {
    auth_type = var.auth_type
    profile_name = var.config_file_profile
    compartment_id = var.entity_compartment_id
    entity_id = var.entity_id
    loggroup_id = var.loggroup_id
#    current_time = local.current_time
    path = format("%q", var.filepath)
  }

  provisioner "local-exec" {
    command = "python3 ./scripts/manageassocs.py -o upsert -a ${self.triggers.auth_type} -p ${self.triggers.profile_name} -c ${self.triggers.compartment_id} -e ${self.triggers.entity_id} -l ${self.triggers.loggroup_id} -f ${self.triggers.path}"
  }

  provisioner "local-exec" {
    when = destroy
    command = "python ./scripts/manageassocs.py -o delete -a ${self.triggers.auth_type} -p ${self.triggers.profile_name} -c ${self.triggers.compartment_id} -e ${self.triggers.entity_id} -l ${self.triggers.loggroup_id} -f ${self.triggers.path}"
  }
}
