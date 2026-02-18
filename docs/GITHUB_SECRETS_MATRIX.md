# GitHub Secrets Matrix

## terraform-infra repository

Required by runtime secret sync workflow (`.github/workflows/sync-runtime-secrets.yml`):

- `SOPS_AGE_KEY`
- `TAILSCALE_AUTHKEY_CI`
- `TEST_SSH_TARGET`
- `PROD_SSH_TARGET`

Required by Terraform workflows (`.github/workflows/terraform-plan.yml`, `.github/workflows/terraform-apply.yml`):

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

- `TAILSCALE_AUTHKEY_CI`
- `TEST_SSH_TARGET`
- `PROD_SSH_TARGET`
- `GHCR_PULL_USERNAME`
- `GHCR_PULL_TOKEN`

Optional:

- `CODECOV_TOKEN`
