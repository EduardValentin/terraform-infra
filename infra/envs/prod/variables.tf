variable "project_prefix" {
  type    = string
  default = "courseplatform"
}

variable "domain_name" {
  type    = string
  default = "courseplatform.com"
}

variable "enable_hetzner" {
  type    = bool
  default = true
}

variable "enable_cloudflare" {
  type    = bool
  default = false
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
  default   = ""
}

variable "cloudflare_zone_id" {
  type    = string
  default = ""
}

variable "hcloud_location" {
  type    = string
  default = "fsn1"
}

variable "server_type" {
  type    = string
  default = "cpx11"
}

variable "server_image" {
  type    = string
  default = "ubuntu-24.04"
}

variable "prod_host_subdomain" {
  type    = string
  default = "app"
}

variable "prod_additional_hostnames" {
  type    = list(string)
  default = []
}

variable "prod_ipv4_override" {
  type    = string
  default = ""
}

variable "bootstrap_bundle_repo" {
  type    = string
  default = "EduardValentin/terraform-infra"
}

variable "bootstrap_bundle_version" {
  type    = string
  default = "v0.1.0"
}

variable "tailscale_auth_key_prod" {
  type      = string
  sensitive = true
}

variable "tailscale_tags_prod" {
  type    = string
  default = "tag:prod"
}

variable "prod_pg_backup_enabled" {
  type    = bool
  default = true
}

variable "prod_pg_backup_oncalendar" {
  type    = string
  default = "*-*-* 03:15:00"
}

variable "prod_pg_backup_local_dir" {
  type    = string
  default = "/srv/backups/postgres"
}

variable "prod_pg_backup_local_retention_days" {
  type    = number
  default = 14
}

variable "prod_pg_backup_nas_dir" {
  type    = string
  default = ""
}

variable "prod_pg_backup_nas_retention_days" {
  type    = number
  default = 14
}

variable "host_labels" {
  type = map(string)
  default = {
    env     = "prod"
    app     = "courseplatform"
    service = "apphost"
  }
}
