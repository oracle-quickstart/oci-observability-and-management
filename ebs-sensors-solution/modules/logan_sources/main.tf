
resource "oci_log_analytics_log_analytics_import_custom_content" "test_sources" {
    namespace = var.namespace
    is_overwrite = false
    for_each = fileset("${var.path}", "*.zip")
        import_custom_content_file = "${var.path}/${each.value}"
}
