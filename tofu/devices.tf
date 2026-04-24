data "tailscale_device" "prodesk" {
  hostname = "prodesk"
  wait_for = "60s"
}

resource "tailscale_device_subnet_routes" "prodesk" {
  device_id = data.tailscale_device.prodesk.node_id
  routes    = ["192.168.1.0/24"]
}

import {
  to = tailscale_device_subnet_routes.prodesk
  id = data.tailscale_device.prodesk.node_id
}
