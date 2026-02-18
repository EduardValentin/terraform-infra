locals {
  primary_hostname = "${var.prod_host_subdomain}.${var.domain_name}"
  hostnames        = distinct(concat([local.primary_hostname], var.prod_additional_hostnames))
}

module "prod_host" {
  count       = var.enable_hetzner ? 1 : 0
  source      = "../../modules/hetzner_host"
  name        = "${var.project_prefix}-prod"
  server_type = var.server_type
  image       = var.server_image
  location    = var.hcloud_location
  labels      = var.host_labels
  user_data = templatefile("../../templates/cloud-init-prod.tftpl", {
    app_name                           = var.project_prefix
    bundle_repo                        = var.bootstrap_bundle_repo
    bundle_version                     = var.bootstrap_bundle_version
    tailscale_auth_key                 = var.tailscale_auth_key_prod
    tailscale_tags                     = var.tailscale_tags_prod
    prod_pg_backup_enabled             = var.prod_pg_backup_enabled
    prod_pg_backup_oncalendar          = var.prod_pg_backup_oncalendar
    prod_pg_backup_local_dir           = var.prod_pg_backup_local_dir
    prod_pg_backup_local_retention_days = var.prod_pg_backup_local_retention_days
    prod_pg_backup_nas_dir             = var.prod_pg_backup_nas_dir
    prod_pg_backup_nas_retention_days  = var.prod_pg_backup_nas_retention_days
  })
}

locals {
  prod_ipv4 = var.enable_hetzner ? module.prod_host[0].ipv4 : var.prod_ipv4_override
  prod_ipv6 = var.enable_hetzner ? module.prod_host[0].ipv6 : ""
}

module "prod_dns" {
  count   = var.enable_cloudflare ? 1 : 0
  source  = "../../modules/cloudflare_dns"
  zone_id = var.cloudflare_zone_id
  records = concat(
    [for hostname in local.hostnames : {
      name    = replace(hostname, ".${var.domain_name}", "")
      type    = "A"
      content = local.prod_ipv4
      ttl     = 120
      proxied = false
      comment = "prod app"
    }],
    local.prod_ipv6 == "" ? [] : [for hostname in local.hostnames : {
      name    = replace(hostname, ".${var.domain_name}", "")
      type    = "AAAA"
      content = local.prod_ipv6
      ttl     = 120
      proxied = false
      comment = "prod app"
    }]
  )
}
