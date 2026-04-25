variable "healthchecksio_api_key" {
  description = "Healthchecks.io API key. Set via TF_VAR_healthchecksio_api_key."
  type        = string
  sensitive   = true
}

provider "healthchecksio" {
  api_key = var.healthchecksio_api_key
}

data "healthchecksio_channel" "email" {
  kind = "email"
}

resource "healthchecksio_check" "prodesk_heartbeat" {
  name     = "prodesk-heartbeat"
  desc     = "Liveness ping from prodesk via runitor"
  tags     = ["prodesk", "heartbeat"]
  timeout  = 1800
  grace    = 600
  channels = [data.healthchecksio_channel.email.id]
}
