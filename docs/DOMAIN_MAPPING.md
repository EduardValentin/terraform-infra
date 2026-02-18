# Domain Mapping Strategy

Current domain root is a placeholder: `courseplatform.com`.

## Current usage

- TEST Tailscale TLS hostname: `susanoo-test.longhair-eagle.ts.net`
- TEST VM node hostname: `susanoo-test.longhair-eagle.ts.net`
- OPS VM node hostname: `susanoo-ops.longhair-eagle.ts.net`
- PROD placeholder host can be `app.courseplatform.com`

In current single-node cert mode, TEST TLS hostname matches the TEST node hostname.

## Future brand domains

To map multiple user-facing brand domains to the same service:

1. Configure `app_brand_domains` in `/Users/trocaneduard/Documents/Personal/terraform-infra/infra/envs/controlplane/terraform.tfvars`.
2. Run `terraform output generated_app_domains` from `infra/envs/controlplane` to confirm desired hostname matrix.
3. Add hostnames to `prod_additional_hostnames` in `/Users/trocaneduard/Documents/Personal/terraform-infra/infra/envs/prod/variables.tf` values.
4. Keep Traefik routers matching all desired hostnames.
5. If using Cloudflare Terraform, add A/AAAA records via `infra/modules/cloudflare_dns`.
6. Keep deployment image unchanged; only DNS + route host rules change.

This keeps app deploy artifacts domain-agnostic.
