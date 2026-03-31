# Phase 0 Prerequisites

This is the current prerequisite baseline for the infrastructure that is live today.

## Required now

### Tailscale

- Tailnet exists and is healthy.
- MagicDNS is enabled.
- Host tags exist and are assignable:
  - `tag:test`
  - `tag:ops`
  - `tag:prod`
  - `tag:solus-agent`
- CI tags exist and are assignable:
  - `tag:ci-app-deploy`
  - `tag:ci-secrets`
  - `tag:ci-terraform`
- One OAuth client exists for CI automation with `Auth Keys: Write` and allowed tags:
  - `tag:ci-app-deploy`
  - `tag:ci-secrets`
  - `tag:ci-terraform`
- Reusable pre-auth keys exist for long-lived host bootstrap and recovery only:
  - `tag:test`
  - `tag:ops`
  - `tag:prod`
- Tailscale SSH is enabled for admin identities.
- Public SSH stays closed on PROD.

### GitHub

- Repositories exist:
  - `EduardValentin/course-platform`
  - `EduardValentin/terraform-infra`
- GitHub environments exist where required:
  - `test`
  - `production`
- Required repository secrets and variables are configured as described in `docs/GITHUB_SECRETS_MATRIX.md`.
- Repository variables should include stable node hostnames for CI SSH target resolution:
  - `TEST_NODE_HOSTNAME`
  - `PROD_NODE_HOSTNAME`

### Runtime secret management

- Local `age` keypair is generated for SOPS.
- `.sops.yaml` contains the correct age public key.
- `terraform-infra` GitHub secret `SOPS_AGE_KEY` contains the matching private key.

### Terraform backend

- OPS VM is running and reachable over Tailscale.
- OPS bootstrap has MinIO backend enabled.
- `terraform-infra` repository secrets are set:
  - `TF_BACKEND_CONFIG_CONTROLPLANE`
  - `TF_BACKEND_CONFIG_TEST`
  - `TF_BACKEND_CONFIG_OPS`
  - `TF_BACKEND_CONFIG_PROD`
  - `TFVARS_CONTROLPLANE`
  - `TFVARS_TEST`
  - `TFVARS_OPS`
  - `TFVARS_PROD`

## Optional later

### Public DNS automation

Cloudflare is supported by the repository but is not required for the current TEST and OPS setup.

Only add Cloudflare prerequisites when public DNS will actually be managed from Terraform:

- Create or choose the public zone.
- Create a token with:
  - `Zone:DNS:Edit`
  - `Zone:Zone:Read`
- Add the token and zone id to the relevant Terraform variable payloads.

## Done criteria

- Tailscale ACL policy applies cleanly and tags are assignable.
- GitHub repositories have the required secrets and variables.
- Runtime secret encryption and decryption work end to end.
- Terraform plan can initialize against the OPS-hosted backend.
- Cloudflare prerequisites are only required when public DNS automation is activated.
