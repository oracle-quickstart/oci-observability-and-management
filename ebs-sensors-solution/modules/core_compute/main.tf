# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

data "oci_core_images" "instance_source_images" {
  compartment_id   = var.compartment_ocid
  operating_system = "Oracle Linux"
  sort_by          = "TIMECREATED"
  sort_order       = "DESC"
  state            = "AVAILABLE"

  filter {
    name   = "display_name"
    values = ["Oracle-Linux-(7\\.[0-9]+)-([\\.0-9]+)-([\\.0-9-]+)$"]
    regex  = true
  }
}

data "oci_core_shapes" "test_shapes" {
  compartment_id = var.compartment_ocid
  image_id       = local.image_ocid
}

locals {
  image_ocid    = lookup(data.oci_core_images.instance_source_images.images[0], "id")
  shape_details = [for s in data.oci_core_shapes.test_shapes.shapes : s if s.name == "${var.compute_shape}"][0]
}

resource "oci_core_instance" "mgmtagent_instance" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = var.display_name
  shape               = var.compute_shape

  source_details {
    source_type = "image"
    source_id   = local.image_ocid
  }

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = true
    is_monitoring_disabled   = true
    plugins_config {
      name          = "Management Agent"
      desired_state = "ENABLED"
    }
  }

  create_vnic_details {
    assign_public_ip = true
    subnet_id        = var.subnet_id
  }

  # Use defaults
  shape_config {
    memory_in_gbs = local.shape_details.memory_in_gbs
    ocpus         = local.shape_details.ocpus
  }

  metadata = {
    ssh_authorized_keys = var.public_key
    user_data = base64encode(templatefile(format("%s/%s", path.module, "cloud-init.sh"),
      {
        tenancy_id       = var.tenancy_id,
        secret_ocid      = var.db_secret_ocid,
        username         = var.db_user,
        entity_name      = var.db_name,
        compartment_ocid = var.compartment_ocid
        log_group_ocid   = var.log_group_ocid
        namespace        = var.namespace
        bucket_name      = var.bucket_name
        schedule_file    = var.file_name
    }))
  }
}
