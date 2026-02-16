output "record_ids" {
  value = [for record in cloudflare_dns_record.record : record.id]
}
