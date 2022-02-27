variable "compartment_id" {
  description = "compartment OCID"
  type        = string
}
variable "load_balancer_id" {
  description = "Load Balancer OCID"
  type        = string
}

variable "web_app_firewall_policy_display_name" {
  description = "WAF policy name"
  type        = string
  default = "Web Applicaiton policy"
}

variable "web_app_firewall_display_name" {
  description = "WAF firewall name"
  type        = string
  default = "Web Application Firewall"
}

variable "log_group_name" {
  description = "log group name"
  type        = string
  default     = "tr_waflb"
}
variable "log_group_compartment_id" {
  description = "compartment id for log group"
  type        = string
  default     = null
}

variable "logging_log_display_name" {
  description = "logs display name"
  type        = string
  default     = "waf_lb_logs"
}

variable "allow_action" {
  description = "define allow action"
  type = object({
    name = string,
    type = string
  })
  default = {
    name = "Allow Action"
    type = "ALLOW"
  }

}

variable "check_action" {
  description = "define check action"
  type = object({
    name = string,
    type = string
  })
  default = {
    name = "Check Action"
    type = "CHECK"
  }
}

variable "protection_rules_action" {
  description = "define protection rules action"
  type = object({
    name         = string,
    type         = string,
    code         = number,
    header_name  = string,
    header_value = string,
    body_type    = string,
    body_text    = string
  })
  default = {
    name         = "Protection Rules Block"
    type         = "RETURN_HTTP_RESPONSE"
    code         = 403
    header_name  = "blocked"
    header_value = "by Protection Rules"
    body_type    = "STATIC_TEXT"
    body_text    = "<html><body><h1 style=\"color: #4485b8;\"> Blocked By Protection Rules</h1></body></html>"
  }
}

variable "iprl_rules_action" {
  description = "define IPRL action"
  type = object({
    name         = string,
    type         = string,
    code         = number,
    header_name  = string,
    header_value = string,
    body_type    = string,
    body_text    = string
  })
  default = {
    name         = "IPRL Block"
    type         = "RETURN_HTTP_RESPONSE"
    code         = 409
    header_name  = "blocked"
    header_value = "by IPRL Rules"
    body_type    = "STATIC_TEXT"
    body_text    = "<html><body><h1 style=\"color: #4485b8;\"> Blocked By IPRL</h1></body></html>"
  }
}

variable "access_rules_action" {
  description = "define IPRL action"
  type = object({
    name         = string,
    type         = string,
    code         = number,
    header_name  = string,
    header_value = string,
    body_type    = string,
    body_text    = string
  })
  default = {
    name         = "Access Rules Block"
    type         = "RETURN_HTTP_RESPONSE"
    code         = 401
    header_name  = "blocked"
    header_value = "by Acess Rules"
    body_type    = "STATIC_TEXT"
    body_text    = "<html><body><h1 style=\"color: #4485b8;\"> Blocked By Access Rules</h1></body></html>"
  }
}
