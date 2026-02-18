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

`TF_BACKEND_CONFIG_*` should contain backend configuration (for example remote state backend args).
`TFVARS_*` should contain the full environment-specific variable payload for the corresponding root.

## terraform-infra repository

- `HCLOUD_TOKEN`
- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ZONE_ID`
- `TAILSCALE_TAILNET`
- `TAILSCALE_OAUTH_CLIENT_ID`
- `TAILSCALE_OAUTH_SECRET`
- `SOPS_AGE_KEY`

## course-platform repository

- `GHCR_PAT` (if not using default `GITHUB_TOKEN` flow)
- `TAILSCALE_TAILNET`
- `TAILSCALE_OAUTH_CLIENT_ID`
- `TAILSCALE_OAUTH_SECRET`
- `TAILSCALE_TEST_HOST`
- `TAILSCALE_PROD_HOST`
- `TEST_DEPLOY_USER`
- `PROD_DEPLOY_USER`
- `OTLP_ENDPOINT`
- `OTLP_HEADERS`

## environment-scoped

### test

- `TAILSCALE_AUTH_KEY_TEST`
- `APP_ENV=test`

### ops

- `TAILSCALE_AUTH_KEY_OPS`
- `OPS_GRAFANA_ADMIN_PASSWORD`
- `APP_ENV=ops`

### prod

- `TAILSCALE_AUTH_KEY_PROD`
- `APP_ENV=prod`
- required reviewers enabled
