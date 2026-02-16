# RUNBOOK

## Active scope

- Phase 0: prerequisites and access baseline
- Phase 1: terraform scaffold and bootstrap release pipeline
- Phase 2: OPS observability stack
- Phase 3: TEST apphost edge + telemetry agents

## Build bootstrap bundle

```bash
cd /Users/trocaneduard/Documents/Personal/terraform-infra
./scripts/package_bootstrap_bundle.sh v0.1.0
ls -lh dist/bootstrap-bundle-v0.1.0.tar.gz
sha256sum dist/bootstrap-bundle-v0.1.0.tar.gz
```

## TEST host bootstrap

```bash
curl -fsSL -o /tmp/bootstrap-bundle.tar.gz "https://github.com/EduardValentin/terraform-infra/releases/download/v0.1.0/bootstrap-bundle-v0.1.0.tar.gz"
mkdir -p /opt/bootstrap
tar -xzf /tmp/bootstrap-bundle.tar.gz -C /opt/bootstrap
ROLE=apphost \
ENVIRONMENT=test \
TAILSCALE_AUTH_KEY=tskey-test \
TAILSCALE_TAGS='tag:test' \
APP_NAME=courseplatform \
OPS_LOKI_URL='http://ops.longhair-eagle.ts.net:3100/loki/api/v1/push' \
/opt/bootstrap/scripts/bootstrap.sh
```

## OPS host bootstrap

```bash
curl -fsSL -o /tmp/bootstrap-bundle.tar.gz "https://github.com/EduardValentin/terraform-infra/releases/download/v0.1.0/bootstrap-bundle-v0.1.0.tar.gz"
mkdir -p /opt/bootstrap
tar -xzf /tmp/bootstrap-bundle.tar.gz -C /opt/bootstrap
ROLE=ops \
ENVIRONMENT=ops \
TAILSCALE_AUTH_KEY=tskey-ops \
TAILSCALE_TAGS='tag:ops' \
APP_NAME=courseplatform \
TEST_HOSTS='courseplatform-test.longhair-eagle.ts.net' \
PROD_HOSTS='' \
LOW_RESOURCE_MODE=false \
OPS_GRAFANA_ADMIN_PASSWORD='change-me' \
/opt/bootstrap/scripts/bootstrap.sh
```

## OPS low-resource mode

Use for 1 vCPU / 2 GB OPS VM:

```bash
LOW_RESOURCE_MODE=true ROLE=ops ENVIRONMENT=ops /opt/bootstrap/scripts/bootstrap.sh
```

Low-resource mode effects:

- Loki uses conservative ingestion limits and a slower compaction interval.
- Tempo uses lower ingestion limits and smaller block duration.
- You should also set application trace sampling to 10-20% (for example `OTEL_TRACES_SAMPLER=parentbased_traceidratio` and `OTEL_TRACES_SAMPLER_ARG=0.2`).
- Expect reduced trace coverage and potential delay for high-volume log indexing.

## Verify TEST host

```bash
docker compose --env-file /srv/edge/.env -f /srv/edge/docker-compose.yml ps
docker compose --env-file /srv/apps/observability/.env -f /srv/apps/observability/docker-compose.yml ps
ls -la /srv/edge/certs/courseplatform-test.longhair-eagle.ts.net
cat /srv/edge/dynamic/tls-certs.yml
curl -kI https://courseplatform-test.longhair-eagle.ts.net
```

## Verify OPS host

```bash
docker compose --env-file /srv/ops/.env -f /srv/ops/docker-compose.yml ps
cat /srv/ops/prometheus/targets/test.json
cat /srv/ops/prometheus/targets/prod.json
curl -s http://localhost:9090/-/healthy
curl -s http://localhost:9093/-/healthy
curl -s http://localhost:3100/ready
curl -s http://localhost:3200/ready
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
