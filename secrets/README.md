# Secrets

Store encrypted secret files only.

## Runtime secret layout

Encrypted runtime env files are stored per environment and app:

- `secrets/runtime/test/<app>.app.env.enc`
- `secrets/runtime/test/<app>.postgres.env.enc`
- `secrets/runtime/prod/<app>.app.env.enc`
- `secrets/runtime/prod/<app>.postgres.env.enc`

Example templates:

- `secrets/runtime/templates/courseplatform.app.env.example`
- `secrets/runtime/templates/courseplatform.postgres.env.example`

## Encrypt runtime secret files

1. Create plaintext files outside this repo (for example in `/tmp`).
2. Encrypt and write tracked `.enc` files:

```bash
./scripts/secrets/encrypt_runtime_secret_set.sh test courseplatform /tmp/courseplatform.app.env /tmp/courseplatform.postgres.env
```

3. Remove plaintext files from `/tmp`.

## Decrypt locally for verification

```bash
./scripts/secrets/decrypt_runtime_secret_set.sh test courseplatform /tmp/runtime-secret-check
```

## Age key requirements

- `.sops.yaml` must contain your real age public key.
- GitHub repository secret `SOPS_AGE_KEY` must contain the matching private key content for CI decryption.

## Sync encrypted runtime secrets to hosts

Use workflow:

- `.github/workflows/sync-runtime-secrets.yml`

It decrypts runtime env files in CI and installs:

- `/srv/apps/<app>/.env`
- `/srv/postgres/<app>.env`

on the selected TEST or PROD host over Tailscale SSH.

It also auto-runs on push to `main` whenever encrypted runtime files change under `secrets/runtime/**`.
