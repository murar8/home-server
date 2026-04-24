resource "tailscale_tailnet_settings" "tailnet" {
  acls_external_link                          = "https://github.com/murar8/home-server/blob/main/tofu/policy.hujson"
  acls_externally_managed_on                  = true
  devices_approval_on                         = false
  devices_auto_updates_on                     = true
  devices_key_duration_days                   = 180
  https_enabled                               = true
  network_flow_logging_on                     = false
  posture_identity_collection_on              = false
  regional_routing_on                         = false
  users_approval_on                           = true
  users_role_allowed_to_join_external_tailnet = "admin"
}

import {
  to = tailscale_tailnet_settings.tailnet
  id = "tailnet_settings"
}

resource "tailscale_dns_preferences" "magic_dns" {
  magic_dns = true
}

import {
  to = tailscale_dns_preferences.magic_dns
  id = "dns_preferences"
}

