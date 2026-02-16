variable "domain_name" {
  type    = string
  default = "courseplatform.com"
}

variable "ops_subdomain" {
  type    = string
  default = "ops"
}

variable "ops_additional_hostnames" {
  type    = list(string)
  default = []
}

variable "ops_host_ipv4" {
  type    = string
  default = ""
}

variable "ops_host_ipv6" {
  type    = string
  default = ""
}

variable "enable_cloudflare" {
  type    = bool
  default = false
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
