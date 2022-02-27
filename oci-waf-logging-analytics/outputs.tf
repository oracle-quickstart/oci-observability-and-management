# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


output "regional_waf_app_policy_ocid" {
  value = module.regional_waf.waf_policy_ocid
}
output "regional_waf_firewall_ocid" {
  value = module.regional_waf.waf_firewall_ocid
}
output "regional_waf_firewall_log_group_ocid" {
  value = module.regional_waf.log_group_ocid
}
output "regional_waf_firewall_log_ocid" {
  value = module.regional_waf.log_ocid
}
