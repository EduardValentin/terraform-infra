# GitHub Secrets Matrix

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
