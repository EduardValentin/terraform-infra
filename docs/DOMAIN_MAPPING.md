# Domain Mapping Strategy

Current public domain is still a placeholder. The default comes from `placeholder_prod_domain` in `infra/envs/controlplane/variables.tf`.
Public DNS automation is supported by the repository but is not active today.

## Current usage

- Control-plane hostname and domain defaults live in `infra/envs/controlplane/variables.tf`.
- Generated app hostnames are exposed by `terraform -chdir=infra/envs/controlplane output generated_app_domains`.
- Current TEST mode uses the hostnames rendered into the bootstrap env and the host's `/srv/edge/hostnames.txt`.

## Future brand domains

To map multiple public brand domains to the same production service:

1. Update `app_brand_domains` in `infra/envs/controlplane/terraform.tfvars`.
2. Run `terraform output generated_app_domains` from `infra/envs/controlplane` to review the resulting hostname matrix.
3. Ensure the PROD Traefik routers match all intended hostnames.
4. Point DNS for those hostnames at the production edge using your chosen DNS provider.
5. If Cloudflare is adopted later, the existing Cloudflare module can manage those records.

This keeps deployment artifacts domain-agnostic: the image stays the same and only routing plus DNS change.
