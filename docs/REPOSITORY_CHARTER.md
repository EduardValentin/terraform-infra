# Terraform Infra Repository Charter

## Purpose

This repository is the single source of truth for infrastructure and operations delivery for Course Platform.

It must allow:

- repeatable provisioning and host bootstrap
- low-manual operations for TEST, OPS, and PROD
- portability between servers/providers without app redesign
- secure-by-default connectivity and administration

It is designed for human operators and coding agents to share the same constraints, architecture decisions, and operating model.

## Primary Constraints

- CI/CD provider: GitHub Actions
- Registry: GHCR (`ghcr.io`)
- CI deploy path: Tailscale-only SSH
- TEST deploy: automatic on merge to `master`
- PROD deploy: manual approval, same exact image digest promoted from TEST
- TEST and OPS hosts: home server VMs (Unraid), isolated and Tailscale-only
- PROD host: Hetzner VPS in Germany, IPv6 enabled, public ingress only `80/443`
- Admin access: Tailscale SSH, no public SSH requirement
- Edge proxy:
  - `traefik-test` on TEST
  - `traefik-prod` on PROD
- TEST TLS: Tailscale certificates (`tailscale cert`) per hostname in `hostnames.txt`
- PROD TLS: Let's Encrypt ACME HTTP-01 with persistent `acme.json`
- DNS provider: Cloudflare via Terraform
- Placeholder domain today: `courseplatform.com` (must stay easy to swap)
- Observability in OPS: Grafana + Prometheus + Loki + Tempo
  - Loki retention: 30 days
  - Tempo retention: 7 days
  - If OPS runs on 1 vCPU / 2 GB, use low-resource mode with conservative Loki/Tempo ingestion and 10-20% app trace sampling
- Standard labels everywhere: `env`, `app`, `service`, `host`
- No high-cardinality PII labels in Loki (`email`, `username`, `IP` are log fields only)
- Hosts must not require git credentials
- Bootstrap delivery must use versioned release bundle: `bootstrap-bundle-<version>.tar.gz`
- Standard host filesystem layout:
  - `/srv/edge`
  - `/srv/apps/<app>`
  - `/srv/ops`
  - `/srv/postgres`

## Environment Model

- TEST:
  - purpose: pre-production validation
  - host type: home server VM
  - access: Tailscale only
  - VM node hostname: `susanoo-test.longhair-eagle.ts.net`
  - current TLS hostname: `susanoo-test.longhair-eagle.ts.net` (single-node cert mode)
- OPS:
  - purpose: centralized business observability
  - host type: dedicated home server VM
  - access: Tailscale only
  - VM node hostname: `susanoo-ops.longhair-eagle.ts.net`
- PROD:
  - purpose: public production delivery
  - host type: Hetzner VPS
  - public ports: `80`, `443`
  - admin: Tailscale SSH

## Repository Scope

In scope for this repository:

- Terraform modules and environment roots
- Provider-facing resources (Hetzner, Cloudflare)
- Cloud-init templates for host bootstrap
- Provider-agnostic bootstrap scripts
- Edge proxy compose/config (Traefik test/prod)
- Observability compose/config (Grafana/Prometheus/Loki/Tempo)
- Host telemetry agent stack (promtail/exporters)
- Operational runbooks and migration procedures
- Bootstrap bundle packaging and release workflow
- Secret handling baseline (SOPS+age)

Out of scope for this repository:

- application business code
- application feature logic
- internal app schema migrations
- long-term data warehouse/business analytics pipelines

## Architecture Components

### Terraform Layer

- `infra/modules/cloudflare_dns`: reusable DNS records module
- `infra/modules/hetzner_host`: reusable Hetzner host/firewall/IP module
- `infra/envs/controlplane`: shared control-plane IaC (GitHub repo config, Tailscale ACL policy, bootstrap env rendering)
- `infra/envs/test`: DNS + test metadata entrypoint for manually provisioned TEST VM
- `infra/envs/ops`: DNS + ops metadata entrypoint for manually provisioned OPS VM
- `infra/envs/prod`: full PROD provisioning entrypoint (Hetzner + optional DNS)
- `infra/templates/cloud-init-prod.tftpl`: cloud-init bootstrap invocation for PROD

### Bootstrap Layer

- `bootstrap/scripts/bootstrap.sh`: role dispatcher (`apphost`, `ops`)
- `bootstrap/scripts/setup_base.sh`: OS + Docker baseline
- `bootstrap/scripts/setup_tailscale.sh`: tailscale install/join/ssh
- `bootstrap/scripts/setup_layout.sh`: `/srv` contract
- `bootstrap/scripts/setup_apphost.sh`: Traefik + promtail/exporters on TEST/PROD
- `bootstrap/scripts/setup_ops.sh`: OPS stack install/provisioning
- `bootstrap/scripts/setup_traefik_test_certs.sh`: TEST cert generation + Traefik TLS dynamic file

### Edge Layer

- `bootstrap/compose/traefik/test/*`: test edge config with file provider and tailscale certs
- `bootstrap/compose/traefik/prod/*`: prod edge config with ACME

### Observability Layer

- `bootstrap/compose/ops/docker-compose.yml`
- `bootstrap/compose/ops/prometheus/*`
- `bootstrap/compose/ops/alertmanager/*`
- `bootstrap/compose/ops/loki/*`
- `bootstrap/compose/ops/tempo/*`
- `bootstrap/compose/ops/grafana/*`
- `bootstrap/compose/agents/docker-compose.yml` for apphost promtail/node-exporter/cadvisor
- OPS stack also hosts Terraform state backend service (MinIO, Tailscale-only) for CI Terraform runs

### Release Layer

- `scripts/package_bootstrap_bundle.sh`
- `scripts/install_bootstrap_bundle.sh`
- `.github/workflows/release-bootstrap-bundle.yml`

## Flow Between Components

### 1) Infrastructure Provisioning Flow

1. Terraform environment is selected (`test`, `ops`, or `prod`).
2. Terraform creates/updates provider resources.
3. For PROD, Terraform injects cloud-init with release bundle coordinates.
4. Host downloads bundle and runs `bootstrap.sh` with role-specific context.
5. Control-plane Terraform root (`controlplane`) manages GitHub CI/CD settings, Tailscale ACL policy, and rendered bootstrap env payloads.
6. Manual PROD bootstrap path is disabled; PROD bootstrap is cloud-init only.

### 2) Host Bootstrap Flow

1. `setup_base.sh` installs host baseline.
2. `setup_layout.sh` enforces `/srv` contract.
3. `setup_tailscale.sh` joins tailnet with role tags.
4. Role execution:
   - `apphost` -> Traefik + apphost telemetry agents
   - `ops` -> Grafana/Prometheus/Loki/Tempo and targets

### 3) TEST TLS Flow

1. Hostnames are listed in `/srv/edge/hostnames.txt`.
2. systemd timer triggers `setup_traefik_test_certs.sh`.
3. Script requests certs via `tailscale cert` and writes:
   - `/srv/edge/certs/<hostname>/cert.pem`
   - `/srv/edge/certs/<hostname>/key.pem`
4. Script generates `/srv/edge/dynamic/tls-certs.yml` for Traefik file provider.

### 4) Deployment Flow (Target Design)

1. `master` merge in app repo builds/pushes image to GHCR.
2. CI deploys image digest to TEST over Tailscale SSH.
3. Health checks gate success/failure.
4. Manual approval promotes same digest to PROD.

### 5) Observability Data Flow

1. Apphost/edge containers are discovered by promtail.
2. Logs ship to Loki in OPS with labels `env/app/service/host`.
3. Node/container metrics are scraped by OPS Prometheus.
4. Prometheus sends alerts to Alertmanager with env-aware route labels.
5. Application traces ship via OTLP to Tempo in OPS.
6. Grafana reads Prometheus/Loki/Tempo with TEST/PROD folder separation.

## Cost and Scale Strategy

## Current cost posture

- prioritize home server VMs for TEST and OPS
- keep PROD to smallest safe Hetzner footprint when activated
- avoid managed cloud service lock-in for now
- prefer compose + Terraform + scripts over paid control planes

## Current expected scale

- low user volume
- monolith applications
- single host per environment
- one Postgres per host with DB/user per app

## Scale-up plan

- Near term:
  - increase VM resources vertically
  - split noisy workloads (OPS vs apphost)
- Medium term:
  - add second production host and blue/green cutover
  - separate Postgres to dedicated managed or self-hosted node
- Later:
  - introduce multi-host scheduler only if justified by load
  - preserve digest-based deploy invariants and environment parity

## Operations Guide

### Updating business ops images (Grafana/Loki/Tempo/Prometheus)

1. Update image tags in `bootstrap/compose/ops/docker-compose.yml`.
2. Build new bootstrap bundle version.
3. Apply to OPS host by rerunning bootstrap role `ops`.
4. Verify health endpoints and dashboards.

### Operating low-resource OPS mode

Use low-resource mode only when OPS capacity is constrained (1 vCPU / 2 GB class VM).

- Enable with `LOW_RESOURCE_MODE=true` when running `setup_ops.sh`.
- Expected behavior:
  - Loki: conservative ingestion limits and slower compaction cadence.
  - Tempo: lower ingestion limits and smaller block duration.
  - Applications should lower trace sampling to 10-20%.
- Tradeoff:
  - reduced trace detail and slower indexing under burst traffic.

### Updating Traefik or telemetry agents

1. Update image tags/config in corresponding compose files.
2. Build/publish bootstrap bundle.
3. Re-run bootstrap role on target host (`apphost` or `ops`).
4. Verify services and telemetry continuity.

### Production database backup policy

- production apphost bootstrap configures scheduled PostgreSQL backups via systemd timer
- one local copy is retained on host (`/srv/backups/postgres`)
- optional second copy is replicated to NAS path if mounted and writable
- retention is controlled by bootstrap/cloud-init variables and must be validated during PROD rollout

### Operational safety rules

- do not deploy unversioned bootstrap artifacts
- keep bundle versions immutable
- test in TEST before OPS/PROD updates where practical
- keep secrets encrypted at rest in repo (SOPS+age)
- keep runtime env files managed via encrypted repo files under `secrets/runtime/<env>/` and CI sync workflow, not manual host edits

## Migration and Portability Process

### Move TEST or OPS to a new server

1. Provision replacement VM and join tailnet.
2. Download same bootstrap bundle version.
3. Run bootstrap with same role/env and secrets.
4. Repoint DNS (if applicable) and update Prometheus targets.
5. Verify app/ops health and telemetry.
6. Decommission old host after validation.

### Move PROD to another VPS provider

1. Prepare equivalent Terraform module/env inputs for new provider.
2. Keep bootstrap bundle and host role contract unchanged.
3. Bring up replacement host in parallel.
4. Validate edge/TLS/telemetry on replacement.
5. Cut DNS to new host.
6. Keep rollback window with old host active until stable.

Key portability rule: host behavior is driven by release bundle, not git checkout on host.

## Security Posture

- Tailscale tags and ACLs for host segmentation (`tag:test`, `tag:prod`, `tag:ops`, `tag:ci-courseplatform`, `tag:ci-secrets`, `tag:ci-terraform`)
- Tailscale SSH for admin access
- no requirement for public SSH on production
- public exposure on PROD limited to `80/443`
- least-privilege credentials in GitHub secrets

## What Is Done vs What Is Next

Done so far:

- phase scaffold and repository structure
- bootstrap bundle release pipeline
- apphost bootstrap with TEST TLS automation and telemetry agents
- OPS stack baseline with env-separated dashboards and alerts
- runbook/test-first operational flow

Next planned milestones:

- finalize TEST and OPS live bring-up validation
- implement app repository Phase 5 CI/CD by digest (TEST auto, PROD manual)
- activate Hetzner PROD path once subscription is ready
- execute migration drill documentation with measured validation steps

## Agent Guidance

When extending this repository:

- preserve portability contract (`bootstrap-bundle-<version>.tar.gz`)
- preserve env label schema (`env/app/service/host`)
- avoid introducing public admin surface area
- keep TEST and OPS first-class, not PROD-only assumptions
- favor idempotent scripts and deterministic CI outputs
- update this charter when architecture intent changes
