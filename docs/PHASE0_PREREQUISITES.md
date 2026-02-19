# Phase 0 Prerequisites

## Cloudflare

- Create zone for placeholder root domain `courseplatform.com` or replacement domain.
- API token permissions:
  - Zone:DNS:Edit
  - Zone:Zone:Read
- Save token in GitHub secrets as `CLOUDFLARE_API_TOKEN`.
- Save zone id in GitHub secrets as `CLOUDFLARE_ZONE_ID`.

## Tailscale

- Tailnet: `longhair-eagle.ts.net`
- MagicDNS: enabled
- Define tags:
  - `tag:test`
  - `tag:prod`
  - `tag:ops`
  - `tag:ci-courseplatform`
  - `tag:ci-secrets`
  - `tag:ci-terraform`
- Create reusable pre-auth keys scoped per tag set.
- Enable Tailscale SSH for admin identities.
- Keep public SSH closed for production host.

## GitHub

- Owner: `EduardValentin`
- Repositories:
  - `EduardValentin/course-platform`
  - `EduardValentin/terraform-infra`
- Environments:
  - `test`
  - `prod` (manual approval)
- Configure secrets matrix from `/Users/trocaneduard/Documents/Personal/terraform-infra/docs/GITHUB_SECRETS_MATRIX.md`.

## Done criteria

- Cloudflare token tested with Terraform plan.
- Tailscale ACL applied and tags assignable.
- GitHub environments configured with required secrets.
