# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "oci_waf_web_app_firewall_policy" "demo_web_app_firewall_policy" {
  compartment_id = var.compartment_id  
  display_name   = var.web_app_firewall_policy_display_name

  # ALLOW action
  actions {
    name = var.allow_action.name
    type = var.allow_action.type
  }
  #CHECK action
  actions {
    name = var.check_action.name
    type = var.check_action.type
  }
  #Protection Rules Action
  actions {
    name = var.protection_rules_action.name
    type = var.protection_rules_action.type

    code = var.protection_rules_action.code

    body {

      type = var.protection_rules_action.body_type
      text = var.protection_rules_action.body_text
    }
    headers {
      #Required
      name  = var.protection_rules_action.header_name
      value = var.protection_rules_action.header_value
    }
  }

  #IPRL action
  actions {
    name = var.iprl_rules_action.name
    type = var.iprl_rules_action.type
    code = var.iprl_rules_action.code
    headers {
      #Required
      name  = var.iprl_rules_action.header_name
      value = var.iprl_rules_action.header_value
    }
  }

  #Access Rules action
  actions {
    name = var.access_rules_action.name
    type = var.access_rules_action.type
    code = var.access_rules_action.code
    headers {
      #Required
      name  = var.access_rules_action.header_name
      value = var.access_rules_action.header_value
    }
  }

  #IPRL configuration
  request_rate_limiting {
    rules {
      action_name = var.iprl_rules_action.name
      configurations {
        period_in_seconds          = 5
        requests_limit             = 1
        action_duration_in_seconds = 30
      }
      name               = "request limit for example_com"
      type               = "REQUEST_RATE_LIMITING"
      condition          = "i_contains(http.request.host, 'example.com')"
      condition_language = "JMESPATH"
    }
  }

  # Request Access control configuration
  request_access_control {
    default_action_name = var.allow_action.name
    rules {
      type               = "ACCESS_CONTROL"
      name               = "Allow Requests with AllowACL"
      action_name        = var.allow_action.name
      condition          = "i_contains(keys(http.request.headers), 'AllowACL')"
      condition_language = "JMESPATH"
    }
    rules {
      type               = "ACCESS_CONTROL"
      name               = "DETECT Requests with CheckACL"
      action_name        = var.check_action.name
      condition          = "i_contains(keys(http.request.headers), 'CheckACL')"
      condition_language = "JMESPATH"
    }
    rules {
      type               = "ACCESS_CONTROL"
      name               = "Block Requests with Header1"
      action_name        = var.access_rules_action.name
      condition          = "i_contains(keys(http.request.headers), 'Header1')"
      condition_language = "JMESPATH"
    }
  }

  # Response Access control configuration
  response_access_control {
    rules {
      type               = "ACCESS_CONTROL"
      name               = "responseAccessRule"
      action_name        = var.access_rules_action.name
      condition          = "i_contains(keys(http.request.headers), 'test') && http.response.code == `200`"
      condition_language = "JMESPATH"
    }
  }

  # Protection Rules Configuration
  request_protection {
    #LFI Filter Categories - Collaborative Group
    rules {
      type        = "PROTECTION"
      name        = "LFI Filter Categories - Collaborative Group"
      action_name = var.protection_rules_action.name
      protection_capabilities {
        key                            = "9300000"
        version                        = 1
        collaborative_action_threshold = 4
        collaborative_weights {
          key    = "9301000"
          weight = 2
        }
        collaborative_weights {
          key    = "9301100"
          weight = 2
        }
        collaborative_weights {
          key    = "9301200"
          weight = 2
        }
        collaborative_weights {
          key    = "9301300"
          weight = 2
        }
        exclusions {
          args            = ["arg1", "arg2"]
          request_cookies = ["cookie1", "/task.*/"]
        }
      }
    }
    # Remote_File_Inclusion
    rules {
      type        = "PROTECTION"
      name        = "Remote_File_Inclusion"
      action_name = var.protection_rules_action.name
      protection_capabilities {
        key     = "931130"
        version = 2
      }
      protection_capabilities {
        key     = "931120"
        version = 2
      }

      protection_capabilities {
        key     = "931100"
        version = 2
      }
    }
  }


}

resource "oci_waf_web_app_firewall" "demo_waf_web_app_firewall" {
  #Required
  compartment_id             = var.compartment_id
  backend_type               = "LOAD_BALANCER"
  load_balancer_id           = var.load_balancer_id
  web_app_firewall_policy_id = oci_waf_web_app_firewall_policy.demo_web_app_firewall_policy.id
  #Optional
  display_name = var.web_app_firewall_display_name
}


resource "oci_logging_log_group" "demo_waf_log_group" {
  #Required
  compartment_id = var.compartment_id
  display_name   = var.log_group_name
}

resource "oci_logging_log" "demo_log" {
  #Required
  display_name = var.logging_log_display_name
  log_group_id = oci_logging_log_group.demo_waf_log_group.id
  log_type     = "SERVICE"

  configuration {
    #Required
    source {
      #Required
      category    = "all"
      resource    = oci_waf_web_app_firewall.demo_waf_web_app_firewall.id
      service     = "waf"
      source_type = "OCISERVICE"
    }
    #Optional
    compartment_id = var.compartment_id
  }

  is_enabled         = "true"
  retention_duration = "30"
}
