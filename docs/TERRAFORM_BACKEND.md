# Terraform Backend (OPS-hosted MinIO)

## Goal

Store Terraform state on your home server (OPS VM) so state is centralized and not tied to a local laptop.

## Design

- Backend type: Terraform `s3` backend
- S3 endpoint: MinIO running on `susanoo-ops`
- Network path: Tailscale-only
- Bucket: `terraform-state`
- State keys:
  - `controlplane/terraform.tfstate`
  - `test/terraform.tfstate`
  - `ops/terraform.tfstate`
  - `prod/terraform.tfstate`

## Why this design

- No paid Terraform Cloud required.
- Works with existing GitHub Actions flow by joining Tailscale from runners.
- Keeps app CI/CD independent from infra backend availability.
  - If OPS/home server is down: app deploy pipelines still work.
  - Infra plan/apply pipelines are expected to fail until OPS is back.

## Bootstrap-driven provisioning on OPS

OPS bootstrap now provisions MinIO backend when these vars are set in `bootstrap-ops.env`:

```dotenv
TERRAFORM_BACKEND_ENABLED=true
TERRAFORM_BACKEND_BUCKET=terraform-state
TERRAFORM_BACKEND_BIND_IP=
TERRAFORM_BACKEND_PORT=9000
TERRAFORM_BACKEND_ACCESS_KEY=terraform-state
TERRAFORM_BACKEND_SECRET_KEY=replace-with-strong-secret
```

`TERRAFORM_BACKEND_BIND_IP` can be left empty to auto-use OPS Tailscale IPv4.

## GitHub Secrets values

Generate backend config payloads:

```bash
./scripts/terraform/render_minio_backend_configs.sh \
  http://susanoo-ops.longhair-eagle.ts.net:9000 \
  terraform-state \
  terraform-state \
  '<strong-random-secret>' \
  ./dist/backend-config
```

Set repo secrets in `terraform-infra`:

- `TF_BACKEND_CONFIG_CONTROLPLANE` <- `./dist/backend-config/controlplane.backend.hcl`
- `TF_BACKEND_CONFIG_TEST` <- `./dist/backend-config/test.backend.hcl`
- `TF_BACKEND_CONFIG_OPS` <- `./dist/backend-config/ops.backend.hcl`
- `TF_BACKEND_CONFIG_PROD` <- `./dist/backend-config/prod.backend.hcl`

## Verification

On OPS VM:

```bash
docker compose --profile tfstate --env-file /srv/ops/.env -f /srv/ops/docker-compose.yml ps
curl -fsS "http://$(awk -F= '$1==\"OPS_TAILSCALE_IPV4\"{print $2}' /srv/ops/.env):9000/minio/health/live" && echo
docker logs --tail 50 ops-terraform-state-init
```

In GitHub Actions (`terraform-infra`):

- Run `Terraform Plan` with `workflow_dispatch` target `controlplane`.
- Confirm `Terraform init` succeeds using backend secret config.

## Rotation

Rotate backend credentials by:

1. Updating `TERRAFORM_BACKEND_ACCESS_KEY`/`TERRAFORM_BACKEND_SECRET_KEY` in OPS bootstrap env.
2. Re-running OPS bootstrap.
3. Re-generating backend HCL payloads.
4. Updating all four `TF_BACKEND_CONFIG_*` GitHub secrets.

