# Terraform Backend (OPS-hosted MinIO)

## Goal

Store Terraform state on your home server (OPS VM) so state is centralized and not tied to a local laptop.

## Design

- Backend type: Terraform `s3` backend
- S3 endpoint: MinIO running on the OPS host
- Network path: Tailscale-only
- Backend defaults and generated state keys are sourced from:
  - `infra/envs/controlplane/variables.tf`
  - `infra/templates/bootstrap-ops.env.tftpl`
  - `scripts/terraform/render_minio_backend_configs.sh`

## Why this design

- No paid Terraform Cloud required.
- Works with existing GitHub Actions flow by joining Tailscale from runners.
- Keeps app CI/CD independent from infra backend availability.
  - If OPS/home server is down: app deploy pipelines still work.
  - Infra plan/apply pipelines are expected to fail until OPS is back.

## Bootstrap-driven provisioning on OPS

OPS bootstrap provisions MinIO from the Terraform-rendered bootstrap payload.
The source template is `infra/templates/bootstrap-ops.env.tftpl`; defaults and overrides are in `infra/envs/controlplane/variables.tf`.
`TERRAFORM_BACKEND_BIND_IP` can be left empty in the rendered env to auto-use the OPS Tailscale IPv4.

## GitHub Secrets values

Generate backend config payloads:

```bash
./scripts/terraform/render_minio_backend_configs.sh \
  <endpoint> \
  <bucket> \
  <access-key> \
  '<strong-random-secret>' \
  ./dist/backend-config
```

The generated files are named after each Terraform environment. The matching GitHub secret names are defined in `.github/workflows/terraform-plan.yml` and `.github/workflows/terraform-apply.yml`.

## Verification

On OPS VM:

```bash
docker compose --profile tfstate --env-file /srv/ops/.env -f /srv/ops/docker-compose.yml ps
curl -fsS "http://$(awk -F= '$1=="OPS_TAILSCALE_IPV4"{ip=$2} $1=="TERRAFORM_BACKEND_PORT"{port=$2} END{print ip":"port}' /srv/ops/.env)/minio/health/live" && echo
docker logs --tail 50 ops-terraform-state-init
```

In GitHub Actions (`terraform-infra`):

- Run `Terraform Plan` with `workflow_dispatch` target `controlplane`.
- Confirm `Terraform init` succeeds using backend secret config.

## Rotation

Rotate backend credentials by:

1. Updating the backend access-key/secret-key values in the control-plane tfvars payload.
2. Re-running OPS bootstrap.
3. Re-generating backend HCL payloads.
4. Updating the Terraform backend GitHub secrets consumed by the Terraform workflows.
