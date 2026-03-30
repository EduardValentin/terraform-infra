# Domain Mapping Strategy

Current public domain is still a placeholder: `courseplatform.com`.
Public DNS automation is supported by the repository but is not active today.

## Current usage

- TEST node hostname: `susanoo-test.longhair-eagle.ts.net`
- TEST TLS hostname: `susanoo-test.longhair-eagle.ts.net`
- OPS node hostname: `susanoo-ops.longhair-eagle.ts.net`
- Current TEST mode uses a single node-level Tailscale certificate.

## Future brand domains

To map multiple public brand domains to the same production service:

1. Update `app_brand_domains` in `infra/envs/controlplane/terraform.tfvars`.
2. Run `terraform output generated_app_domains` from `infra/envs/controlplane` to review the resulting hostname matrix.
3. Ensure the PROD Traefik routers match all intended hostnames.
4. Point DNS for those hostnames at the production edge using your chosen DNS provider.
5. If Cloudflare is adopted later, the existing Cloudflare module can manage those records.

This keeps deployment artifacts domain-agnostic: the image stays the same and only routing plus DNS change.
