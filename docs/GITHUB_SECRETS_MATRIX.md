# GitHub Secrets Matrix

Primary management path: `infra/envs/controlplane` Terraform root.
Use `github_repository_variables`, `github_repository_secrets`, `github_environment_variables`, and `github_environment_secrets` inputs.

## Terraform automation secrets (terraform-infra repo)

These are consumed by:

- `.github/workflows/terraform-plan.yml` (auto checks + plan)
- `.github/workflows/terraform-apply.yml` (manual apply button)

Required multi-line secrets:

- `TF_BACKEND_CONFIG_CONTROLPLANE`
- `TF_BACKEND_CONFIG_TEST`
- `TF_BACKEND_CONFIG_OPS`
- `TF_BACKEND_CONFIG_PROD`

- `TFVARS_CONTROLPLANE`
- `TFVARS_TEST`
- `TFVARS_OPS`
- `TFVARS_PROD`

`TF_BACKEND_CONFIG_*` should contain backend configuration for the `s3` backend (MinIO on OPS).
`TFVARS_*` should contain the full environment-specific variable payload for the corresponding root.

Recommended MinIO backend payloads:

- `TF_BACKEND_CONFIG_CONTROLPLANE`
```hcl
bucket                      = "terraform-state"
key                         = "controlplane/terraform.tfstate"
region                      = "us-east-1"
endpoints = {
  s3 = "http://susanoo-ops.longhair-eagle.ts.net:9000"
}
access_key                  = "terraform-state"
secret_key                  = "replace-with-strong-secret"
skip_credentials_validation = true
skip_region_validation      = true
skip_metadata_api_check     = true
use_path_style              = true
```

- `TF_BACKEND_CONFIG_TEST`
```hcl
bucket                      = "terraform-state"
key                         = "test/terraform.tfstate"
region                      = "us-east-1"
endpoints = {
  s3 = "http://susanoo-ops.longhair-eagle.ts.net:9000"
}
access_key                  = "terraform-state"
secret_key                  = "replace-with-strong-secret"
skip_credentials_validation = true
skip_region_validation      = true
skip_metadata_api_check     = true
use_path_style              = true
```

- `TF_BACKEND_CONFIG_OPS`
```hcl
bucket                      = "terraform-state"
key                         = "ops/terraform.tfstate"
region                      = "us-east-1"
endpoints = {
  s3 = "http://susanoo-ops.longhair-eagle.ts.net:9000"
}
access_key                  = "terraform-state"
secret_key                  = "replace-with-strong-secret"
skip_credentials_validation = true
skip_region_validation      = true
skip_metadata_api_check     = true
use_path_style              = true
```

- `TF_BACKEND_CONFIG_PROD`
```hcl
bucket                      = "terraform-state"
key                         = "prod/terraform.tfstate"
region                      = "us-east-1"
endpoints = {
  s3 = "http://susanoo-ops.longhair-eagle.ts.net:9000"
}
access_key                  = "terraform-state"
secret_key                  = "replace-with-strong-secret"
skip_credentials_validation = true
skip_region_validation      = true
skip_metadata_api_check     = true
use_path_style              = true
```

## terraform-infra repository

Required by runtime secret sync workflow (`.github/workflows/sync-runtime-secrets.yml`):

- `SOPS_AGE_KEY`
- `TAILSCALE_OAUTH_CLIENT_ID`
- `TAILSCALE_OAUTH_SECRET`
- `TEST_SSH_TARGET`
- `PROD_SSH_TARGET`
- `TEST_SSH_KNOWN_HOSTS`
- `PROD_SSH_KNOWN_HOSTS`

Required by Terraform workflows (`.github/workflows/terraform-plan.yml`, `.github/workflows/terraform-apply.yml`):

- `TAILSCALE_OAUTH_CLIENT_ID`
- `TAILSCALE_OAUTH_SECRET`
- `TF_BACKEND_CONFIG_CONTROLPLANE`
- `TF_BACKEND_CONFIG_TEST`
- `TF_BACKEND_CONFIG_OPS`
- `TF_BACKEND_CONFIG_PROD`
- `TFVARS_CONTROLPLANE`
- `TFVARS_TEST`
- `TFVARS_OPS`
- `TFVARS_PROD`

Provider/API secrets used by Terraform roots (depending on enabled modules):

- `HCLOUD_TOKEN`
- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ZONE_ID`
- `TAILSCALE_TAILNET`
- `TAILSCALE_OAUTH_CLIENT_ID`
- `TAILSCALE_OAUTH_SECRET`

## course-platform repository

Deployment/build secrets (current workflows):

- `TAILSCALE_AUTHKEY_CI_COURSEPLATFORM`
- `TEST_SSH_TARGET`
- `PROD_SSH_TARGET`
- `TEST_SSH_KNOWN_HOSTS`
- `PROD_SSH_KNOWN_HOSTS`
- `GHCR_PULL_USERNAME`
- `GHCR_PULL_TOKEN`

Optional:

- `CODECOV_TOKEN`

## Pinned SSH host key secrets

Use host key pinning secrets (not `accept-new`) for CI SSH:

```bash
ssh-keyscan -H susanoo-test.longhair-eagle.ts.net 2>/dev/null
ssh-keyscan -H <prod-hostname-or-ip> 2>/dev/null
```

Copy the full output line(s) into:

- `TEST_SSH_KNOWN_HOSTS`
- `PROD_SSH_KNOWN_HOSTS`
