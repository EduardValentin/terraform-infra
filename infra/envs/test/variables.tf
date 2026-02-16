variable "domain_name" {
  type    = string
  default = "courseplatform.com"
}

variable "test_subdomain" {
  type    = string
  default = "courseplatform-test"
}

variable "test_additional_hostnames" {
  type    = list(string)
  default = []
}

variable "test_host_ipv4" {
  type    = string
  default = ""
}

variable "test_host_ipv6" {
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
