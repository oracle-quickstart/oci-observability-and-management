data "oci_identity_tenancy" "this" {
    #Required
    tenancy_id = var.tenancy_ocid
}
