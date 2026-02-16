output "prod_ipv4" {
  value = try(module.prod_host[0].ipv4, "")
}

output "prod_ipv6" {
  value = try(module.prod_host[0].ipv6, "")
}

output "prod_hostnames" {
  value = local.hostnames
}
