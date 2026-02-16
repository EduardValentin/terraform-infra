# Domain Mapping Strategy

Current domain root is a placeholder: `courseplatform.com`.

## Current usage

- TEST Tailscale TLS hostname: `courseplatform-test.longhair-eagle.ts.net`
- PROD placeholder host can be `app.courseplatform.com`

## Future brand domains

To map multiple user-facing brand domains to the same service:

1. Add hostnames to `prod_additional_hostnames` in `/Users/trocaneduard/Documents/Personal/terraform-infra/infra/envs/prod/variables.tf` values.
2. Keep Traefik routers matching all desired hostnames.
3. If using Cloudflare Terraform, add A/AAAA records via `infra/modules/cloudflare_dns`.
4. Keep deployment image unchanged; only DNS + route host rules change.

This keeps app deploy artifacts domain-agnostic.
