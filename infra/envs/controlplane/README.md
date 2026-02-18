# Control-plane Terraform root

This Terraform root manages:

- GitHub repository settings for CI/CD (environments, variables, optional secrets)
- Tailscale ACL policy using `tailscale_acl`
- Generated bootstrap env payloads for TEST/OPS/PROD hosts

## Safety notes

- Do not commit plaintext secrets in `terraform.tfvars`.
- Use secret injection at runtime (`TF_VAR_*`) or encrypted files (SOPS) for:
  - `github_token`
  - `github_repository_secrets`
  - `github_environment_secrets`
  - `tailscale_oauth_client_id`
  - `tailscale_oauth_client_secret`
  - bootstrap auth keys/password fields
- Terraform state can contain sensitive values for GitHub secret resources. Use a protected state backend in real environments.

## Usage

```bash
cd infra/envs/controlplane
cp terraform.tfvars.example terraform.tfvars
cat > backend.hcl <<'EOF'
bucket                      = "terraform-state"
key                         = "controlplane/terraform.tfstate"
region                      = "us-east-1"
endpoint                    = "http://susanoo-ops.longhair-eagle.ts.net:9000"
access_key                  = "terraform-state"
secret_key                  = "replace-with-strong-secret"
skip_credentials_validation = true
skip_region_validation      = true
skip_metadata_api_check     = true
force_path_style            = true
EOF
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Render bootstrap env outputs

```bash
terraform output -raw bootstrap_test_env > /tmp/bootstrap-test.env
terraform output -raw bootstrap_ops_env > /tmp/bootstrap-ops.env
terraform output -raw bootstrap_prod_env > /tmp/bootstrap-prod.env
chmod 600 /tmp/bootstrap-test.env /tmp/bootstrap-ops.env /tmp/bootstrap-prod.env
```
