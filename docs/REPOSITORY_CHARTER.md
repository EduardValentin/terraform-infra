# Terraform Infra Repository Charter

## Purpose

This repository is the single source of truth for infrastructure and operations delivery for Course Platform.

It exists to provide:

- repeatable provisioning and host bootstrap
- low-manual operations for TEST, OPS, and later PROD
- portability between servers and providers without app redesign
- secure-by-default connectivity and administration

It is meant to be usable by both human operators and coding agents.

## Primary constraints

- CI/CD provider: GitHub Actions
- Registry: GHCR (`ghcr.io`)
- CI deploy path: Tailscale-only SSH
- TEST deploy: automatic from app CI on merges to `main`
- PROD deploy: manual promotion of the exact same image digest used in TEST
- TEST and OPS hosts: home server VMs, isolated and Tailscale-only
- PROD host target: Hetzner VPS in Germany, IPv6 enabled, public ingress only on `80/443`
- Admin access: Tailscale SSH, no public SSH
- Edge proxy:
  - `traefik-test` on TEST
  - `traefik-prod` on PROD
- TEST TLS: Tailscale certificates managed from `/srv/edge/hostnames.txt`
- PROD TLS: Let's Encrypt ACME HTTP-01 with persistent `acme.json`
- Public DNS automation is optional and not active yet
- Placeholder public domain remains `courseplatform.com` until a real production domain is chosen
- Observability in OPS: Grafana + Prometheus + Loki + Tempo
  - Loki retention: 30 days
  - Tempo retention: 7 days
  - If OPS runs on 1 vCPU / 2 GB, use low-resource mode and lower trace sampling
- Standard labels everywhere: `env`, `app`, `service`, `host`
- No high-cardinality PII labels in Loki
- Hosts must not require git credentials
- Bootstrap delivery uses immutable release bundles: `bootstrap-bundle-<version>.tar.gz`
- Standard host filesystem layout:
  - `/srv/edge`
  - `/srv/apps/<app>`
  - `/srv/ops`
  - `/srv/postgres`

## Environment model

- TEST:
  - purpose: pre-production validation
  - host type: home server VM
  - access: Tailscale only
  - VM node hostname: `susanoo-test`
  - current TLS hostname: `susanoo-test.longhair-eagle.ts.net`
- OPS:
  - purpose: centralized business observability and Terraform backend
  - host type: dedicated home server VM
  - access: Tailscale only
  - VM node hostname: `susanoo-ops`
- PROD:
  - purpose: public production delivery
  - host type: Hetzner VPS
  - public ports: `80`, `443`
  - admin: Tailscale SSH

## Repository scope

In scope:

- Terraform modules and environment roots
- control-plane IaC for GitHub configuration and Tailscale ACLs
- cloud-init for PROD bootstrap
- provider-agnostic bootstrap scripts
- Traefik test/prod compose and config
- observability stack compose and config
- apphost telemetry agents
- runtime secret handling baseline
- bootstrap bundle packaging and release workflow
- runbooks and migration procedures

Supported but not currently active:

- public DNS automation through Terraform
- Hetzner production provisioning

Out of scope:

- application business code
- application feature logic
- application schema migrations
- long-term analytics pipelines

## Architecture components

### Terraform layer

- `infra/envs/controlplane`: GitHub repo config, Tailscale ACL policy, rendered bootstrap env payloads
- `infra/envs/test`: metadata and optional future DNS for the manually provisioned TEST VM
- `infra/envs/ops`: metadata and optional future DNS for the manually provisioned OPS VM
- `infra/envs/prod`: Hetzner provisioning and optional DNS for PROD
- `infra/modules/hetzner_host`: reusable Hetzner host/firewall/IP module
- `infra/modules/cloudflare_dns`: optional DNS module for later public DNS automation
- `infra/templates/cloud-init-prod.tftpl`: cloud-init bootstrap invocation for PROD

### Bootstrap layer

- `bootstrap/scripts/bootstrap.sh`: role dispatcher for `apphost` and `ops`
- `bootstrap/scripts/setup_base.sh`: OS and Docker baseline
- `bootstrap/scripts/setup_tailscale.sh`: Tailscale install, join, and SSH setup
- `bootstrap/scripts/setup_layout.sh`: `/srv` contract
- `bootstrap/scripts/setup_apphost.sh`: Traefik and telemetry agents on TEST/PROD
- `bootstrap/scripts/setup_ops.sh`: OPS stack and MinIO backend provisioning
- `bootstrap/scripts/setup_traefik_test_certs.sh`: TEST certificate renewal and Traefik TLS config generation

### Edge layer

- `bootstrap/compose/traefik/test/*`: TEST Traefik config using Tailscale certificates
- `bootstrap/compose/traefik/prod/*`: PROD Traefik config using ACME

### Observability layer

- `bootstrap/compose/ops/docker-compose.yml`
- `bootstrap/compose/ops/prometheus/*`
- `bootstrap/compose/ops/alertmanager/*`
- `bootstrap/compose/ops/loki/*`
- `bootstrap/compose/ops/tempo/*`
- `bootstrap/compose/ops/grafana/*`
- `bootstrap/compose/agents/docker-compose.yml`
- OPS also hosts the Tailscale-only MinIO backend used by Terraform CI

### Release layer

- `scripts/package_bootstrap_bundle.sh`
- `scripts/install_bootstrap_bundle.sh`
- `.github/workflows/release-bootstrap-bundle.yml`

## Flow between components

### 1) Infrastructure provisioning flow

1. A Terraform environment is selected.
2. Terraform creates or updates shared control-plane and provider resources.
3. For PROD, Terraform injects cloud-init with bundle coordinates.
4. The target host downloads the release bundle and runs `bootstrap.sh` with role-specific context.
5. The `controlplane` root manages GitHub CI/CD settings, Tailscale ACLs, and rendered bootstrap env content.
6. PROD is intended to bootstrap through cloud-init, not through an ad-hoc manual bootstrap path.

### 2) Host bootstrap flow

1. `setup_base.sh` installs the OS baseline.
2. `setup_layout.sh` enforces the `/srv` directory contract.
3. `setup_tailscale.sh` joins the tailnet with the correct role tag.
4. Role execution:
   - `apphost` installs Traefik and apphost telemetry agents
   - `ops` installs Grafana, Prometheus, Loki, Tempo, and MinIO backend services

### 3) TEST TLS flow

1. Hostnames are listed in `/srv/edge/hostnames.txt`.
2. A systemd timer runs `setup_traefik_test_certs.sh`.
3. The script requests certificates with `tailscale cert` and writes:
   - `/srv/edge/certs/<hostname>/cert.pem`
   - `/srv/edge/certs/<hostname>/key.pem`
4. The script regenerates `/srv/edge/dynamic/tls-certs.yml` for Traefik.

### 4) Application deployment flow

1. The app repo builds and pushes an image to GHCR.
2. CI deploys that image digest to TEST over Tailscale SSH.
3. Health checks gate success or failure.
4. Manual approval later promotes the same digest to PROD.

### 5) Observability data flow

1. Apphost and edge containers are discovered by promtail.
2. Logs ship to Loki with `env`, `app`, `service`, and `host` labels.
3. OPS Prometheus scrapes node and container metrics.
4. Alertmanager handles environment-aware alert routing.
5. Applications send traces to Tempo over OTLP.
6. Grafana reads Prometheus, Loki, and Tempo with TEST/PROD separation.

## Cost and scale strategy

### Current cost posture

- prefer home server VMs for TEST and OPS
- keep PROD on the smallest safe Hetzner footprint when activated
- avoid managed control-plane costs where possible
- prefer Terraform + compose + bootstrap scripts over heavier orchestration

### Current expected scale

- low user volume
- monolith applications
- single host per environment
- one Postgres instance per host with DB and user per app

### Scale-up plan

- near term:
  - increase VM resources vertically
  - keep OPS separate from app workloads
- medium term:
  - add second production host only if load justifies it
  - move Postgres to a dedicated node or managed service if needed
- later:
  - introduce multi-host scheduling only when there is a real operational need

## Operations guide

### Updating OPS images

1. Update image tags in `bootstrap/compose/ops/docker-compose.yml`.
2. Publish a new bootstrap bundle.
3. Re-run the `ops` bootstrap role.
4. Verify health endpoints and dashboards.

### Updating Traefik or telemetry agents

1. Update the relevant compose or config files.
2. Publish a new bootstrap bundle.
3. Re-run the target bootstrap role.
4. Verify services and telemetry continuity.

### Low-resource OPS mode

Use low-resource mode only on a constrained OPS VM.

- enable it with `LOW_RESOURCE_MODE=true`
- expect reduced trace detail and slower indexing under burst traffic
- lower application trace sampling to match

### Runtime secrets operations

- keep runtime secrets encrypted in repo with SOPS + age
- sync them to hosts through the runtime secret workflow
- avoid manual host edits for normal secret changes

### Production backup policy

- PROD is designed to run scheduled PostgreSQL backups via systemd
- one local copy is retained on the host
- a second copy can be replicated to NAS if mounted and writable
- retention stays bootstrap-driven and should be validated during PROD rollout

## Migration and portability

### Move TEST or OPS to a new server

1. Provision the replacement VM.
2. Join it to Tailscale.
3. Install the same bootstrap bundle version.
4. Run bootstrap with the same role and env values.
5. Reconnect observability or routing as needed.
6. Decommission the old host after validation.

### Move PROD to another VPS provider

1. Build an equivalent Terraform module or env input set for the new provider.
2. Keep the bootstrap contract unchanged.
3. Bring up the replacement host in parallel.
4. Validate edge, TLS, and telemetry.
5. Update public DNS.
6. Keep the old host available during the rollback window.

Key portability rule: host behavior is driven by the release bundle, not by a git checkout on the host.

## Security posture

- Tailscale tags and ACLs segment hosts and CI identities
- admin access uses Tailscale SSH
- no public SSH is required for production
- PROD public exposure is limited to `80/443`
- CI credentials are split by function where practical
- runtime secrets are encrypted at rest in git

## Current state and next steps

Implemented now:

- repository scaffold and env roots
- bootstrap bundle packaging and release workflow
- TEST apphost bootstrap with Tailscale TLS automation and telemetry agents
- OPS stack with Grafana, Prometheus, Loki, Tempo, and MinIO backend
- control-plane Terraform for GitHub settings and Tailscale ACL policy
- runtime secret sync via SOPS + age and GitHub Actions
- app CI/CD path for digest-based TEST deploys

Still to do:

- activate Hetzner PROD path when the VPS is ready
- decide whether to adopt Terraform-managed public DNS
- run documented migration and restore drills
- improve multi-app observability so OPS can scrape and dashboard multiple apps by default

## Agent guidance

When extending this repository:

- preserve the release-bundle portability contract
- preserve the `env`/`app`/`service`/`host` label schema
- avoid adding public admin surface area
- keep TEST and OPS as first-class environments
- favor idempotent scripts and deterministic CI outputs
- update this charter when architecture intent changes
