provider "b2" {}

resource "b2_bucket" "restic" {
  for_each = toset(["prodesk", "desktop", "thinkpad"])

  bucket_name = "murar8-${each.key}-restic"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }
}
