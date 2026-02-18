terraform {
  required_version = ">= 1.8.0"
  backend "s3" {}

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.22"
    }
  }
}
