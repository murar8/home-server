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

resource "healthchecksio_check" "prodesk_system" {
  name     = "prodesk-system"
  desc     = "Every 30min: systemctl is-system-running on prodesk. Doubles as liveness."
  tags     = ["prodesk", "system"]
  timeout  = 1800
  grace    = 300
  channels = [data.healthchecksio_channel.email.id]
}

resource "healthchecksio_check" "prodesk_disk" {
  name     = "prodesk-disk"
  desc     = "Daily: /, /persist, /nix below 85% on prodesk."
  tags     = ["prodesk", "disk"]
  timeout  = 86400
  grace    = 7200
  channels = [data.healthchecksio_channel.email.id]
}

resource "healthchecksio_check" "prodesk_smart" {
  name     = "prodesk-smart"
  desc     = "Daily: smartctl -H on all prodesk disks."
  tags     = ["prodesk", "smart"]
  timeout  = 86400
  grace    = 7200
  channels = [data.healthchecksio_channel.email.id]
}

resource "healthchecksio_check" "prodesk_restic" {
  name     = "prodesk-restic"
  desc     = "Daily: restic B2 backup completion on prodesk."
  tags     = ["prodesk", "restic"]
  timeout  = 86400
  grace    = 7200
  channels = [data.healthchecksio_channel.email.id]
}
