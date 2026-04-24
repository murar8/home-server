provider "b2" {}

resource "b2_bucket" "prodesk_restic" {
  bucket_name = "murar8-prodesk-restic"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }
}

import {
  to = b2_bucket.prodesk_restic
  id = "381732edc58fa45f97d1031c"
}
