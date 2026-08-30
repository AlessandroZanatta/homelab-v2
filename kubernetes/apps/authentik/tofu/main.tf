terraform {
  required_version = ">= 1.12.0, < 2.0.0"
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    authentik = {
      source  = "registry.terraform.io/goauthentik/authentik"
      version = "~> 2026.5.1"
    }
  }
}

provider "authentik" {
  url      = "https://auth.kalexlab.xyz"
  token    = var.authentik_token
  insecure = true
}
