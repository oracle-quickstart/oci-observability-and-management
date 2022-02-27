output "waf_policy_ocid" {
  description = "WAF policy OCID"
  value       = oci_waf_web_app_firewall_policy.demo_web_app_firewall_policy.id
}
output "waf_firewall_ocid" {
  description = "WAF application firewall OCID"
  value       = oci_waf_web_app_firewall.demo_waf_web_app_firewall.id
}

output "log_group_ocid" {
  description = "Log group OCID"
  value       = oci_logging_log_group.demo_waf_log_group.id
}

output "log_ocid" {
  description = "Log OCID"
  value       = oci_logging_log.demo_log.id
}

