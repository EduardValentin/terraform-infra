locals {
  primary_hostname = "${var.ops_subdomain}.${var.domain_name}"
  hostnames        = distinct(concat([local.primary_hostname], var.ops_additional_hostnames))
  records = concat(
    var.ops_host_ipv4 == "" ? [] : [for hostname in local.hostnames : {
      name    = replace(hostname, ".${var.domain_name}", "")
      type    = "A"
      content = var.ops_host_ipv4
      ttl     = 120
      proxied = false
      comment = "ops"
    }],
    var.ops_host_ipv6 == "" ? [] : [for hostname in local.hostnames : {
      name    = replace(hostname, ".${var.domain_name}", "")
      type    = "AAAA"
      content = var.ops_host_ipv6
      ttl     = 120
      proxied = false
      comment = "ops"
    }]
  )
}

module "ops_dns" {
  count   = var.enable_cloudflare ? 1 : 0
  source  = "../../modules/cloudflare_dns"
  zone_id = var.cloudflare_zone_id
  records = local.records
}
