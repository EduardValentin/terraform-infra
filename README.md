# terraform-infra

Portable infrastructure and bootstrap automation for Course Platform across TEST, OPS, and PROD.

## Structure

- `infra/envs/prod`: Hetzner + Cloudflare managed production entrypoint
- `infra/envs/test`: test environment entrypoint for manually provisioned VM metadata + DNS
- `infra/envs/ops`: ops environment entrypoint for manually provisioned VM metadata + DNS
- `infra/modules/*`: reusable modules
- `bootstrap/*`: provider-agnostic host bootstrap and runtime assets
- `scripts/package_bootstrap_bundle.sh`: build release artifact `bootstrap-bundle-<version>.tar.gz`
- `.github/workflows/release-bootstrap-bundle.yml`: publish bootstrap bundle to GitHub Releases

## Repository charter

- `/Users/trocaneduard/Documents/Personal/terraform-infra/docs/REPOSITORY_CHARTER.md`

## Current approach

- test-first rollout: deploy TEST and OPS on home server before Hetzner PROD
- tailnet: `longhair-eagle.ts.net` with MagicDNS enabled
- bundle source repo: `EduardValentin/terraform-infra`
- VM node hostnames:
  - TEST VM: `susanoo-test`
  - OPS VM: `susanoo-ops`
- TEST app hostname stays `[app]-test.longhair-eagle.ts.net` (for example `courseplatform-test.longhair-eagle.ts.net`)

## Quick start

1. Read `/Users/trocaneduard/Documents/Personal/terraform-infra/docs/PHASE0_PREREQUISITES.md`
2. Configure SOPS age key and bootstrap secrets from `/Users/trocaneduard/Documents/Personal/terraform-infra/secrets/README.md`
3. Build and publish bootstrap bundle:
   - `make bundle VERSION=v0.1.0`
4. Bootstrap hosts:
   - TEST VM: `ROLE=apphost ENVIRONMENT=test ... /opt/bootstrap/scripts/bootstrap.sh`
   - OPS VM: `ROLE=ops ENVIRONMENT=ops ... /opt/bootstrap/scripts/bootstrap.sh`
5. Configure scrape target hostnames on OPS host via `TEST_HOSTS` and `PROD_HOSTS` env in setup command.

## Bootstrap install command

Use this on TEST/OPS manual VM creation and in PROD cloud-init payload:

```bash
curl -fsSL -o /tmp/bootstrap-bundle.tar.gz "https://github.com/EduardValentin/terraform-infra/releases/download/v0.1.0/bootstrap-bundle-v0.1.0.tar.gz" && \
mkdir -p /opt/bootstrap && tar -xzf /tmp/bootstrap-bundle.tar.gz -C /opt/bootstrap && \
ROLE=apphost ENVIRONMENT=test HOSTNAME_OVERRIDE=susanoo-test TAILSCALE_AUTH_KEY=tskey-example TAILSCALE_TAGS='tag:test' /opt/bootstrap/scripts/bootstrap.sh
```

## Brand domain mapping later

See `/Users/trocaneduard/Documents/Personal/terraform-infra/docs/DOMAIN_MAPPING.md`.
