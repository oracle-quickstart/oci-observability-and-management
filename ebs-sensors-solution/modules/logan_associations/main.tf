#locals {
#  current_time = timestamp()
#}

# Upsert Associations
resource null_resource upsert_assocs {
  triggers = {
    compartment_id = var.entity_compartment_id
    entity_id = var.entity_id
    loggroup_id = var.loggroup_id
#    current_time = local.current_time
    path = format("%q", var.filepath)
  }

  provisioner "local-exec" {
    command = "python3 ./scripts/addassocs.py -c ${self.triggers.compartment_id} -e ${self.triggers.entity_id} -l ${self.triggers.loggroup_id} -p ${self.triggers.path}"
  }
}
