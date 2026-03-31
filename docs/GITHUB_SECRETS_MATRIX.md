# GitHub Secrets Matrix

Primary management path: `infra/envs/controlplane` Terraform root.
Use `github_repository_variables`, `github_repository_secrets`, `github_environment_variables`, and `github_environment_secrets` inputs there whenever possible.

## terraform-infra repository

### Required by Terraform workflows

Consumed by:

- `.github/workflows/terraform-plan.yml`
- `.github/workflows/terraform-apply.yml`

Required GitHub secrets:

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

`TF_BACKEND_CONFIG_*` contains the Terraform `s3` backend payload for the OPS-hosted MinIO endpoint.
`TFVARS_*` contains the full environment-specific variable payload for the matching Terraform root.

Recommended MinIO backend payloads:

### `TF_BACKEND_CONFIG_CONTROLPLANE`

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

### `TF_BACKEND_CONFIG_TEST`

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

### `TF_BACKEND_CONFIG_OPS`

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

### `TF_BACKEND_CONFIG_PROD`

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

### Required by runtime secret sync

Consumed by:

- `.github/workflows/sync-runtime-secrets.yml`

Required GitHub secrets:

- `SOPS_AGE_KEY`
- `TAILSCALE_OAUTH_CLIENT_ID`
- `TAILSCALE_OAUTH_SECRET`
- `TEST_SSH_KNOWN_HOSTS`
- `PROD_SSH_KNOWN_HOSTS`

Required GitHub repository variables:

- `TEST_NODE_HOSTNAME`
- `PROD_NODE_HOSTNAME`

## Provider and control-plane values

These are typically carried inside `TFVARS_*`, not as separate GitHub Actions secrets:

- GitHub owner and PAT for control-plane management
- Tailscale tailnet name
- Tailscale OAuth client credentials used by Terraform provider
- bootstrap host pre-auth keys
- OPS Grafana admin password
- OPS Terraform backend credentials
- Hetzner token when PROD provisioning is enabled
- Cloudflare token and zone id only if public DNS is managed through Terraform

OpenCL and regular-member ACL inputs are also configured in `TFVARS_CONTROLPLANE`:

- `tailscale_opencl_agent_tag`
- `tailscale_opencl_account_*`
- `tailscale_opencl_agent_*`
- `tailscale_opencl_admin_*`
- `tailscale_regular_member_sources`
- `tailscale_regular_member_destinations`

## course-platform repository

Deployment/build secrets currently required:

- `TAILSCALE_OAUTH_CLIENT_ID`
- `TAILSCALE_OAUTH_SECRET`
- `TEST_SSH_KNOWN_HOSTS`
- `PROD_SSH_KNOWN_HOSTS`
- `GHCR_PULL_USERNAME`
- `GHCR_PULL_TOKEN`

Deployment/build repository variables:

- `TEST_NODE_HOSTNAME`
- `PROD_NODE_HOSTNAME`

Notes:

- `course-platform` deploy workflows use OAuth-based Tailscale auth.
- `TAILSCALE_AUTHKEY_CI_COURSEPLATFORM` is legacy and is no longer used.

Optional:

- `CODECOV_TOKEN`

## Pinned SSH host key secrets

Use host key pinning secrets, not `StrictHostKeyChecking=accept-new`:

```bash
ssh-keyscan -H susanoo-test.longhair-eagle.ts.net 2>/dev/null
ssh-keyscan -H courseplatform-prod.longhair-eagle.ts.net 2>/dev/null
```

Copy the full output into:

- `TEST_SSH_KNOWN_HOSTS`
- `PROD_SSH_KNOWN_HOSTS`
