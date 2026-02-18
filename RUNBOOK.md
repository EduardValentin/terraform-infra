# RUNBOOK

## Active scope

- Phase 0: prerequisites and access baseline
- Phase 1: terraform scaffold and bootstrap release pipeline
- Phase 2: OPS observability stack
- Phase 3: TEST apphost edge + telemetry agents
- Control-plane IaC: GitHub repo config, Tailscale ACL policy, bootstrap env generation

## Control-plane Terraform

Use Terraform to manage GitHub Actions repo config, Tailscale ACL policy, and rendered bootstrap env payloads.

```bash
cd /Users/trocaneduard/Documents/Personal/terraform-infra/infra/envs/controlplane
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Render bootstrap env files from Terraform outputs:

```bash
terraform output -raw bootstrap_test_env > /tmp/bootstrap-test.env
terraform output -raw bootstrap_ops_env > /tmp/bootstrap-ops.env
terraform output -raw bootstrap_prod_env > /tmp/bootstrap-prod.env
chmod 600 /tmp/bootstrap-test.env /tmp/bootstrap-ops.env /tmp/bootstrap-prod.env
```

## Terraform CI/CD workflows

Automatic plan/checks:

- Workflow: `Terraform Plan`
- Trigger: push to `main` when `infra/**` Terraform files change
- Behavior:
  - detects impacted roots (`controlplane`, `test`, `ops`, `prod`)
  - runs `init`, `fmt -check`, `validate`, and `plan`
  - uploads plan artifacts per environment

Manual apply:

- Workflow: `Terraform Apply`
- Trigger: manual (`workflow_dispatch`)
- Inputs:
  - `target_environment` (`controlplane`, `test`, `ops`, `prod`, `all`)
  - `ref`
  - `confirm=APPLY`
- Behavior:
  - reruns `init`, `fmt -check`, `validate`, and `plan`
  - applies using generated plan file

Backend connectivity note:

- Terraform workflows join Tailscale (`tag:ci`) before `terraform init`.
- Remote state backend is expected at OPS MinIO endpoint (`susanoo-ops.longhair-eagle.ts.net:9000`).
- If OPS VM is down, Terraform plan/apply workflows fail, but application CI/CD in `course-platform` still works.

## Terraform backend on OPS VM (MinIO)

OPS bootstrap now provisions a Tailscale-only MinIO service for Terraform remote state.

Required vars in `/root/bootstrap/bootstrap-ops.env`:

- `TERRAFORM_BACKEND_ENABLED=true`
- `TERRAFORM_BACKEND_BUCKET=terraform-state`
- `TERRAFORM_BACKEND_BIND_IP=` (leave empty to auto-use OPS Tailscale IPv4)
- `TERRAFORM_BACKEND_PORT=9000`
- `TERRAFORM_BACKEND_ACCESS_KEY=terraform-state`
- `TERRAFORM_BACKEND_SECRET_KEY=<strong-random-secret>`

Apply/reconcile on OPS host:

```bash
/opt/bootstrap/bootstrap-bundle-<version>/scripts/run_bootstrap_from_env.sh /root/bootstrap/bootstrap-ops.env
```

Verify on OPS host:

```bash
docker compose --profile tfstate --env-file /srv/ops/.env -f /srv/ops/docker-compose.yml ps
curl -fsS "http://$(awk -F= '$1==\"OPS_TAILSCALE_IPV4\"{print $2}' /srv/ops/.env):9000/minio/health/live" && echo
docker logs --tail 50 ops-terraform-state-init
```

Expected:

- `ops-terraform-state` is `Up`
- `ops-terraform-state-init` exits successfully after bucket creation
- MinIO health endpoint returns `200`

Generate backend config snippets locally:

```bash
./scripts/terraform/render_minio_backend_configs.sh \
  http://susanoo-ops.longhair-eagle.ts.net:9000 \
  terraform-state \
  terraform-state \
  '<strong-random-secret>' \
  ./dist/backend-config
```

Then copy file contents into GitHub repo secrets:

- `TF_BACKEND_CONFIG_CONTROLPLANE` from `./dist/backend-config/controlplane.backend.hcl`
- `TF_BACKEND_CONFIG_TEST` from `./dist/backend-config/test.backend.hcl`
- `TF_BACKEND_CONFIG_OPS` from `./dist/backend-config/ops.backend.hcl`
- `TF_BACKEND_CONFIG_PROD` from `./dist/backend-config/prod.backend.hcl`

## Build bootstrap bundle

```bash
cd /Users/trocaneduard/Documents/Personal/terraform-infra
./scripts/package_bootstrap_bundle.sh 0.1.10
ls -lh dist/bootstrap-bundle-0.1.10.tar.gz
sha256sum dist/bootstrap-bundle-0.1.10.tar.gz
```

## Standardized bootstrap env files

Use bundle templates and keep real env files root-only:

```bash
sudo install -d -m 0700 /root/bootstrap
sudo cp /opt/bootstrap/bootstrap-bundle-0.1.10/env/bootstrap-test.env.template /root/bootstrap/bootstrap-test.env
sudo cp /opt/bootstrap/bootstrap-bundle-0.1.10/env/bootstrap-ops.env.template /root/bootstrap/bootstrap-ops.env
sudo chmod 600 /root/bootstrap/bootstrap-test.env /root/bootstrap/bootstrap-ops.env
sudo nano /root/bootstrap/bootstrap-test.env
sudo nano /root/bootstrap/bootstrap-ops.env
```

Production policy:

- manual PROD bootstrap is disabled
- PROD bootstrap is allowed only via Terraform cloud-init path

## Runtime secrets (encrypted, no manual VM edits)

Use SOPS+age encrypted files under:

- `secrets/runtime/test/*.enc`
- `secrets/runtime/prod/*.enc`

Create encrypted TEST files:

```bash
mkdir -p secrets/runtime/work
cp secrets/runtime/templates/courseplatform.app.env.example secrets/runtime/work/courseplatform.app.env
cp secrets/runtime/templates/courseplatform.postgres.env.example secrets/runtime/work/courseplatform.postgres.env
# edit work files with real values
./scripts/secrets/encrypt_runtime_secret_set.sh test courseplatform secrets/runtime/work/courseplatform.app.env secrets/runtime/work/courseplatform.postgres.env
rm -f secrets/runtime/work/courseplatform.app.env secrets/runtime/work/courseplatform.postgres.env
```

Update existing runtime secrets:

```bash
./scripts/secrets/edit_runtime_secret_set.sh prepare test courseplatform
# edit files in secrets/runtime/work/test-courseplatform/
./scripts/secrets/edit_runtime_secret_set.sh apply test courseplatform
git add secrets/runtime/test/courseplatform.app.env.enc secrets/runtime/test/courseplatform.postgres.env.enc
git commit -m "CP-56 update test runtime secrets"
git push
./scripts/secrets/edit_runtime_secret_set.sh cleanup test courseplatform
```

If encrypted files do not exist yet, `prepare` seeds work files from templates automatically.

Then run GitHub Actions workflow:

- `.github/workflows/sync-runtime-secrets.yml`
  - `environment=test`
  - `app_name=courseplatform`

Or push encrypted runtime secret file changes to `main`; the workflow auto-detects and syncs changed env/app targets.

This updates:

- `/srv/apps/courseplatform/.env`
- `/srv/postgres/courseplatform.env`

without manual SSH secret edits.

## TEST host bootstrap

```bash
curl -fsSL -o /tmp/bootstrap-bundle.tar.gz "https://github.com/EduardValentin/terraform-infra/releases/download/0.1.10/bootstrap-bundle-0.1.10.tar.gz"
mkdir -p /opt/bootstrap
tar -xzf /tmp/bootstrap-bundle.tar.gz -C /opt/bootstrap
/opt/bootstrap/bootstrap-bundle-0.1.10/scripts/run_bootstrap_from_env.sh /root/bootstrap/bootstrap-test.env
```

Notes:

- Apphost bootstrap requires a connected Tailscale node identity and IPv4 address.
- For TEST, Traefik and exporter ports bind to the Tailscale IPv4 only.
- TEST VM node hostname should be `susanoo-test`.
- TEST TLS hostname defaults to `susanoo-test.longhair-eagle.ts.net`.

## OPS host bootstrap

```bash
curl -fsSL -o /tmp/bootstrap-bundle.tar.gz "https://github.com/EduardValentin/terraform-infra/releases/download/0.1.10/bootstrap-bundle-0.1.10.tar.gz"
mkdir -p /opt/bootstrap
tar -xzf /tmp/bootstrap-bundle.tar.gz -C /opt/bootstrap
/opt/bootstrap/bootstrap-bundle-0.1.10/scripts/run_bootstrap_from_env.sh /root/bootstrap/bootstrap-ops.env
```

## OPS low-resource mode

Use for 1 vCPU / 2 GB OPS VM:

```bash
LOW_RESOURCE_MODE=true /opt/bootstrap/bootstrap-bundle-0.1.10/scripts/run_bootstrap_from_env.sh /root/bootstrap/bootstrap-ops.env
```

Low-resource mode effects:

- Loki uses conservative ingestion limits and a slower compaction interval.
- Tempo uses lower ingestion limits and smaller block duration.
- You should also set application trace sampling to 10-20% (for example `OTEL_TRACES_SAMPLER=parentbased_traceidratio` and `OTEL_TRACES_SAMPLER_ARG=0.2`).
- Expect reduced trace coverage and potential delay for high-volume log indexing.

## PROD scheduled PostgreSQL backups

This is configured via bootstrap variables and cloud-init for `ENVIRONMENT=prod`.

Settings:

- `PROD_PG_BACKUP_ENABLED=true`
- `PROD_PG_BACKUP_ONCALENDAR="*-*-* 03:15:00"`
- `PROD_PG_BACKUP_LOCAL_DIR=/srv/backups/postgres`
- `PROD_PG_BACKUP_LOCAL_RETENTION_DAYS=14`
- `PROD_PG_BACKUP_NAS_DIR=/mnt/nas/courseplatform-backups` (optional)
- `PROD_PG_BACKUP_NAS_RETENTION_DAYS=14`

Manual verification on PROD host:

```bash
systemctl status course-platform-pg-backup.timer --no-pager
systemctl list-timers --all | grep course-platform-pg-backup || true
sudo systemctl start course-platform-pg-backup.service
journalctl -u course-platform-pg-backup.service -n 50 --no-pager
ls -lah /srv/backups/postgres
ls -lah /mnt/nas/courseplatform-backups
```

Expected:

- Timer is enabled and active.
- Manual service run completes successfully.
- New `*.sql.gz` file appears in local backup dir.
- If NAS path is mounted/writable, same file appears in NAS dir.
- Older files are pruned according to retention days.

## Verify TEST host

```bash
docker compose --env-file /srv/edge/.env -f /srv/edge/docker-compose.yml ps
docker compose --env-file /srv/apps/observability/.env -f /srv/apps/observability/docker-compose.yml ps
cat /srv/edge/.env
cat /srv/apps/observability/.env
cat /srv/apps/observability/promtail.yml
ls -la /srv/edge/certs/susanoo-test.longhair-eagle.ts.net
cat /srv/edge/dynamic/tls-certs.yml
curl -kI https://susanoo-test.longhair-eagle.ts.net
systemctl status tailscale-cert-renew.timer --no-pager
systemctl start tailscale-cert-renew.service
journalctl -u tailscale-cert-renew.service -n 20 --no-pager
stat -c '%y %n' /srv/edge/dynamic/tls-certs.yml /srv/edge/certs/susanoo-test.longhair-eagle.ts.net/cert.pem /srv/edge/certs/susanoo-test.longhair-eagle.ts.net/key.pem
echo | openssl s_client -connect susanoo-test.longhair-eagle.ts.net:443 -servername susanoo-test.longhair-eagle.ts.net 2>/dev/null | openssl x509 -noout -subject -issuer -enddate
tailscale ip -4
ss -ltnp | egrep '(:80|:443|:9100|:8080)'
```

Expected:

- `/srv/edge/.env` contains `TRAEFIK_BIND_IP=<tailscale-ipv4>`.
- `/srv/apps/observability/.env` contains `METRICS_BIND_IP=<tailscale-ipv4>`.
- `/srv/apps/observability/promtail.yml` contains label keep rule `logging=promtail`.
- `tailscale-cert-renew.timer` is active and `tailscale-cert-renew.service` runs without errors.
- `tls-certs.yml`, `cert.pem`, and `key.pem` update timestamps after a manual renewal run.
- `openssl s_client` returns the renewed certificate for `susanoo-test.longhair-eagle.ts.net`.
- `ss -ltnp` shows `80/443/9100/8080` bound to the Tailscale IPv4, not `0.0.0.0`.

## Verify OPS host

```bash
docker compose --env-file /srv/ops/.env -f /srv/ops/docker-compose.yml ps
cat /srv/ops/prometheus/targets/test.json
cat /srv/ops/prometheus/targets/prod.json
curl -s http://localhost:9090/-/healthy
docker exec ops-alertmanager sh -lc 'wget -qO- http://127.0.0.1:9093/-/healthy || curl -fsS http://127.0.0.1:9093/-/healthy'
curl -s http://localhost:3100/ready
curl -s http://localhost:3200/ready
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.env=="test") | {scrapeUrl: .scrapeUrl, health: .health, labels: .labels}'
curl -G -s http://localhost:3100/loki/api/v1/query --data-urlencode 'query=sum(count_over_time({env="test",app="courseplatform"}[5m]))'
grep -n \"ingestion_rate_mb\" /srv/ops/loki/config.yml || true
```

## Grafana checks

- Open `http://<ops-tailnet-host>:3000` over Tailscale.
- Confirm folders `TEST` and `PROD` exist.
- Confirm dashboards show environment banner and `host` variable.
- Confirm Prometheus alerts distinguish severity:
  - `env=test` -> low priority
  - `env=prod` -> primary/critical
- Confirm Alertmanager routing config loaded:
  - `docker exec ops-alertmanager cat /etc/alertmanager/alertmanager.yml`
  - test alerts route to `test-low-priority`
  - prod alerts route to `prod-primary`

## Rollback

- Redeploy previous bootstrap bundle version:
  - download prior `bootstrap-bundle-<version>.tar.gz`
  - rerun `bootstrap.sh` with same role/env
- Restart stack with previous config:

```bash
docker compose --env-file /srv/edge/.env -f /srv/edge/docker-compose.yml up -d
docker compose --env-file /srv/ops/.env -f /srv/ops/docker-compose.yml up -d
```

- Keep bundle versions immutable in GitHub Releases.
