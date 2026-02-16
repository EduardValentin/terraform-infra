locals {
  records_by_key = {
    for record in var.records : "${record.type}-${record.name}" => record
  }
}

resource "cloudflare_dns_record" "record" {
  for_each = local.records_by_key

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  ttl     = each.value.ttl
  proxied = each.value.proxied
  comment = each.value.comment
}
