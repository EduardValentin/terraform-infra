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

Notes:

- Apphost bootstrap requires a connected Tailscale node identity and IPv4 address.
- For TEST, Traefik and exporter ports bind to the Tailscale IPv4 only.

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
cat /srv/edge/.env
cat /srv/apps/observability/.env
cat /srv/apps/observability/promtail.yml
ls -la /srv/edge/certs/courseplatform-test.longhair-eagle.ts.net
cat /srv/edge/dynamic/tls-certs.yml
curl -kI https://courseplatform-test.longhair-eagle.ts.net
systemctl status tailscale-cert-renew.timer --no-pager
systemctl start tailscale-cert-renew.service
journalctl -u tailscale-cert-renew.service -n 20 --no-pager
stat -c '%y %n' /srv/edge/dynamic/tls-certs.yml /srv/edge/certs/courseplatform-test.longhair-eagle.ts.net/cert.pem /srv/edge/certs/courseplatform-test.longhair-eagle.ts.net/key.pem
echo | openssl s_client -connect courseplatform-test.longhair-eagle.ts.net:443 -servername courseplatform-test.longhair-eagle.ts.net 2>/dev/null | openssl x509 -noout -subject -issuer -enddate
tailscale ip -4
ss -ltnp | egrep '(:80|:443|:9100|:8080)'
```

Expected:

- `/srv/edge/.env` contains `TRAEFIK_BIND_IP=<tailscale-ipv4>`.
- `/srv/apps/observability/.env` contains `METRICS_BIND_IP=<tailscale-ipv4>`.
- `/srv/apps/observability/promtail.yml` contains label keep rule `logging=promtail`.
- `tailscale-cert-renew.timer` is active and `tailscale-cert-renew.service` runs without errors.
- `tls-certs.yml`, `cert.pem`, and `key.pem` update timestamps after a manual renewal run.
- `openssl s_client` returns the renewed certificate for `courseplatform-test.longhair-eagle.ts.net`.
- `ss -ltnp` shows `80/443/9100/8080` bound to the Tailscale IPv4, not `0.0.0.0`.

## Verify OPS host

```bash
docker compose --env-file /srv/ops/.env -f /srv/ops/docker-compose.yml ps
cat /srv/ops/prometheus/targets/test.json
cat /srv/ops/prometheus/targets/prod.json
curl -s http://localhost:9090/-/healthy
curl -s http://localhost:9093/-/healthy
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
