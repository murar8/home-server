terraform {
  required_version = ">= 1.10.0"

  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.28"
    }
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.12"
    }
  }

  backend "s3" {
    bucket = "murar8-home-server-opentofu"
    key    = "terraform.tfstate"
    region = "eu-central-003"
    endpoints = {
      s3 = "https://s3.eu-central-003.backblazeb2.com"
    }

    # B2 is S3-compatible but not AWS; disable AWS-specific behaviour.
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}
