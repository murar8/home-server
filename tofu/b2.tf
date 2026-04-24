provider "b2" {}

resource "b2_bucket" "prodesk_restic" {
  bucket_name = "murar8-prodesk-restic"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }
}
