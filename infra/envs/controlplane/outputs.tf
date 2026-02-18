output "tailscale_policy_json" {
  value       = local.tailscale_policy_json
  description = "Rendered Tailscale ACL policy payload managed by this Terraform root."
}

output "generated_app_domains" {
  value       = local.generated_app_domains
  description = "Per-app domain matrix for TEST and PROD routing/hostnames."
}

output "bootstrap_test_env" {
  value       = local.bootstrap_test_env_content
  description = "Rendered bootstrap env file content for TEST apphost."
  sensitive   = true
}

output "bootstrap_ops_env" {
  value       = local.bootstrap_ops_env_content
  description = "Rendered bootstrap env file content for OPS host."
  sensitive   = true
}

output "bootstrap_prod_env" {
  value       = local.bootstrap_prod_env_content
  description = "Rendered bootstrap env file content for PROD apphost."
  sensitive   = true
}
