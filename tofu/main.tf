provider "tailscale" {}

resource "tailscale_acl" "policy" {
  acl                        = file("${path.module}/policy.hujson")
  overwrite_existing_content = true
}
