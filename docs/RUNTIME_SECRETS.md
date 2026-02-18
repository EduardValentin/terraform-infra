# Runtime Secrets Management (SOPS + age)

This is the primary runtime secret workflow for TEST and PROD.

## Design

1. Runtime secrets are committed encrypted in this repository.
2. Decryption happens only in GitHub Actions using `SOPS_AGE_KEY`.
3. CI syncs decrypted files to hosts over Tailscale SSH.
4. Hosts keep runtime secrets locally at:
   - `/srv/apps/<app>/.env`
   - `/srv/postgres/<app>.env`

No manual secret edits on VM shell are required for normal operations.

## One-time setup

### 1) Install local tools

```bash
brew install sops age
```

### 2) Generate age keypair

```bash
mkdir -p "$HOME/.config/sops/age"
age-keygen -o "$HOME/.config/sops/age/keys.txt"
```

Capture the public key:

```bash
grep '^# public key:' "$HOME/.config/sops/age/keys.txt" | awk '{print $4}'
```

### 3) Configure `.sops.yaml`

Set your real age public key in:

- `.sops.yaml`

### 4) Configure GitHub secret

In `terraform-infra` repository settings, set:

- `SOPS_AGE_KEY`: full private key file content from `$HOME/.config/sops/age/keys.txt`

Also ensure these secrets exist in `terraform-infra`:

- `TAILSCALE_AUTHKEY_CI`
- `TEST_SSH_TARGET`
- `PROD_SSH_TARGET`

## Create encrypted TEST runtime secrets

### 1) Prepare plaintext files from templates

```bash
cp secrets/runtime/templates/courseplatform.app.env.example /tmp/courseplatform.app.env
cp secrets/runtime/templates/courseplatform.postgres.env.example /tmp/courseplatform.postgres.env
```

Edit `/tmp/courseplatform.app.env` and `/tmp/courseplatform.postgres.env` with real values.

### 2) Encrypt into repository-tracked files

```bash
./scripts/secrets/encrypt_runtime_secret_set.sh test courseplatform /tmp/courseplatform.app.env /tmp/courseplatform.postgres.env
```

This writes:

- `secrets/runtime/test/courseplatform.app.env.enc`
- `secrets/runtime/test/courseplatform.postgres.env.enc`

### 3) Remove plaintext temp files

```bash
rm -f /tmp/courseplatform.app.env /tmp/courseplatform.postgres.env
```

### 4) Commit and push

```bash
git add secrets/runtime/test/courseplatform.app.env.enc secrets/runtime/test/courseplatform.postgres.env.enc
git commit -m "CP-56 add encrypted test runtime secrets for courseplatform"
git push
```

## Sync encrypted secrets to TEST host

Run GitHub Actions workflow:

- `Sync Runtime Secrets`

Inputs:

- `environment`: `test`
- `app_name`: `courseplatform`

What it does:

1. Decrypts files with `SOPS_AGE_KEY`.
2. Connects to tailnet with `TAILSCALE_AUTHKEY_CI`.
3. Installs files on TEST host with mode `0600`.

## Verification

```bash
ssh -o ProxyCommand='tailscale nc %h %p' root@susanoo-test "sudo stat -c '%a %n' /srv/apps/courseplatform/.env /srv/postgres/courseplatform.env"
```

Expected permissions:

- `600 /srv/apps/courseplatform/.env`
- `600 /srv/postgres/courseplatform.env`

## Rollout note

Runtime secret file updates do not automatically recreate app containers.

After syncing secrets, run the app deploy workflow (`deploy_by_digest`) so new env values are applied to running containers.
