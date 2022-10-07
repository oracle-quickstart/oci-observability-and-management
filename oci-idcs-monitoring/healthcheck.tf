resource "oci_health_checks_http_monitor" "api_gw_hc" {
  #Required
  compartment_id = "${var.compartment_ocid}"
  display_name = "IdcsAuditLogMonitor-${var.deployment_name}-${random_id.tag.hex}"
  interval_in_seconds = 300
  protocol = "HTTPS"
  targets = [oci_apigateway_gateway.test_gateway.hostname]
  #Optional
  is_enabled = true
  method = "GET"
  path = "/fn/postauditlogs-${var.deployment_name}"
  timeout_in_seconds = 60
  vantage_point_names = [ 
      "aws-sfo"
  ]
}
