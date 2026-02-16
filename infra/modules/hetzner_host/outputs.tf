output "server_id" {
  value = hcloud_server.host.id
}

output "ipv4" {
  value = hcloud_primary_ip.ipv4.ip_address
}

output "ipv6" {
  value = hcloud_primary_ip.ipv6.ip_address
}
