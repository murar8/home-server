provider "tailscale" {}

data "tailscale_device" "prodesk" {
  hostname = "prodesk"
  wait_for = "60s"
}

resource "tailscale_device_subnet_routes" "prodesk" {
  device_id = data.tailscale_device.prodesk.node_id
  routes    = ["192.168.1.0/24"]
}

resource "tailscale_dns_preferences" "magic_dns" {
  magic_dns = true
}

resource "tailscale_tailnet_settings" "tailnet" {
  acls_external_link                          = "https://github.com/murar8/home-server/blob/main/tofu/tailscale.tf"
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

resource "tailscale_acl" "policy" {
  overwrite_existing_content = true
  acl = jsonencode({
    grants = [
      # Allow member devices unrestricted access to other member devices
      {
        src = ["autogroup:member"]
        dst = ["autogroup:member"]
        ip  = ["*"]
      },
      # Allow member devices to access LAN via subnet router
      {
        src = ["autogroup:member"]
        dst = ["192.168.1.0/24"]
        ip  = ["*"]
      },
    ]
    tests = [
      # Members can reach member devices
      {
        src    = "murar8@github"
        accept = ["100.93.230.82:22", "100.90.169.56:22", "100.94.207.109:22"]
      },
      # Members can reach LAN via subnet router
      {
        src    = "murar8@github"
        accept = ["192.168.1.1:80", "192.168.1.130:22"]
      },
    ]
  })
}

