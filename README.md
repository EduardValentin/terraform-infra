# terraform-infra

Portable infrastructure and bootstrap automation for Course Platform across TEST, OPS, and PROD.

## Structure

- `infra/envs/prod`: Hetzner + Cloudflare managed production entrypoint
- `infra/envs/test`: test environment entrypoint for manually provisioned VM metadata + DNS
- `infra/envs/ops`: ops environment entrypoint for manually provisioned VM metadata + DNS
- `infra/envs/controlplane`: Terraform-managed GitHub CI/CD repo config + Tailscale ACL policy + generated bootstrap env payloads
- `infra/modules/*`: reusable modules
- `bootstrap/*`: provider-agnostic host bootstrap and runtime assets
- `scripts/package_bootstrap_bundle.sh`: build release artifact `bootstrap-bundle-<version>.tar.gz`
- `.github/workflows/release-bootstrap-bundle.yml`: publish bootstrap bundle to GitHub Releases
- `.github/workflows/terraform-plan.yml`: auto Terraform checks + plan for impacted roots
- `.github/workflows/terraform-apply.yml`: manual Terraform apply workflow (`workflow_dispatch`)
- `scripts/terraform/render_minio_backend_configs.sh`: generate backend.hcl payloads for GitHub backend secrets

## Repository charter

- `/Users/trocaneduard/Documents/Personal/terraform-infra/docs/REPOSITORY_CHARTER.md`
- `/Users/trocaneduard/Documents/Personal/terraform-infra/docs/TERRAFORM_BACKEND.md`

## Current approach

- test-first rollout: deploy TEST and OPS on home server before Hetzner PROD
- tailnet: `longhair-eagle.ts.net` with MagicDNS enabled
- bundle source repo: `EduardValentin/terraform-infra`
- VM node hostnames:
  - TEST VM: `susanoo-test`
  - OPS VM: `susanoo-ops`
- Current TEST TLS hostname default: `susanoo-test.longhair-eagle.ts.net` (single-node cert mode)
- PROD bootstrap includes scheduled PostgreSQL backups with local retention and optional NAS replication path.
- Terraform state backend target: MinIO on OPS VM over Tailscale (`susanoo-ops.longhair-eagle.ts.net:9000`).

## Quick start

1. Read `/Users/trocaneduard/Documents/Personal/terraform-infra/docs/PHASE0_PREREQUISITES.md`
2. Configure SOPS age key and runtime secret flow:
   - `/Users/trocaneduard/Documents/Personal/terraform-infra/secrets/README.md`
   - `/Users/trocaneduard/Documents/Personal/terraform-infra/docs/RUNTIME_SECRETS.md`
3. Build and publish bootstrap bundle:
   - `make bundle VERSION=v0.1.0`
4. Bootstrap hosts:
   - copy env templates from `bootstrap-bundle-<version>/env/*.template` to `/root/bootstrap/*.env`
   - execute with loader script `bootstrap-bundle-<version>/scripts/run_bootstrap_from_env.sh` for TEST/OPS only
   - PROD bootstrap is cloud-init only (manual PROD bootstrap is intentionally blocked)
5. Configure scrape target hostnames on OPS host via `TEST_HOSTS` and `PROD_HOSTS` env in setup command.
6. Optionally apply control-plane IaC:
   - `cd infra/envs/controlplane`
   - `terraform init && terraform plan -var-file=terraform.tfvars`
7. Sync encrypted runtime secrets to host with GitHub Actions workflow:
   - `.github/workflows/sync-runtime-secrets.yml`
   - auto-triggers on `main` push when `secrets/runtime/**` encrypted files change

## Bootstrap install command

Use this on TEST/OPS manual VM creation:

```bash
curl -fsSL -o /tmp/bootstrap-bundle.tar.gz "https://github.com/EduardValentin/terraform-infra/releases/download/0.1.10/bootstrap-bundle-0.1.10.tar.gz" && \
mkdir -p /opt/bootstrap && tar -xzf /tmp/bootstrap-bundle.tar.gz -C /opt/bootstrap && \
cp /opt/bootstrap/bootstrap-bundle-0.1.10/env/bootstrap-test.env.template /root/bootstrap-test.env && \
chmod 600 /root/bootstrap-test.env && \
/opt/bootstrap/bootstrap-bundle-0.1.10/scripts/run_bootstrap_from_env.sh /root/bootstrap-test.env
```

## Brand domain mapping later

See `/Users/trocaneduard/Documents/Personal/terraform-infra/docs/DOMAIN_MAPPING.md`.
