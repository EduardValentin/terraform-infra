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

Plaintext authoring workspace:

- `secrets/runtime/work/` is gitignored for local temporary env files before encryption.

Update helper script:

- `scripts/secrets/edit_runtime_secret_set.sh`
  - `prepare`: decrypt encrypted files into gitignored work folder; if encrypted files are missing, populate from templates
  - `apply`: encrypt edited work files back into `secrets/runtime/<env>/`
  - `cleanup`: remove local work folder

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

- `TAILSCALE_OAUTH_CLIENT_ID`
- `TAILSCALE_OAUTH_SECRET`
- `TEST_SSH_TARGET`
- `PROD_SSH_TARGET`
- `TEST_SSH_KNOWN_HOSTS`
- `PROD_SSH_KNOWN_HOSTS`

## Create encrypted TEST runtime secrets

### 1) Prepare plaintext files from templates

```bash
mkdir -p secrets/runtime/work
cp secrets/runtime/templates/courseplatform.app.env.example secrets/runtime/work/courseplatform.app.env
cp secrets/runtime/templates/courseplatform.postgres.env.example secrets/runtime/work/courseplatform.postgres.env
```

Edit `secrets/runtime/work/courseplatform.app.env` and `secrets/runtime/work/courseplatform.postgres.env` with real values.

### 2) Encrypt into repository-tracked files

```bash
./scripts/secrets/encrypt_runtime_secret_set.sh test courseplatform secrets/runtime/work/courseplatform.app.env secrets/runtime/work/courseplatform.postgres.env
```

This writes:

- `secrets/runtime/test/courseplatform.app.env.enc`
- `secrets/runtime/test/courseplatform.postgres.env.enc`

### 3) Remove plaintext temp files

```bash
rm -f secrets/runtime/work/courseplatform.app.env secrets/runtime/work/courseplatform.postgres.env
```

## Update existing encrypted secrets (recommended cycle)

```bash
./scripts/secrets/edit_runtime_secret_set.sh prepare test courseplatform
```

Edit:

- `secrets/runtime/work/test-courseplatform/courseplatform.app.env`
- `secrets/runtime/work/test-courseplatform/courseplatform.postgres.env`

Then:

```bash
./scripts/secrets/edit_runtime_secret_set.sh apply test courseplatform
git add secrets/runtime/test/courseplatform.app.env.enc secrets/runtime/test/courseplatform.postgres.env.enc
git commit -m "CP-56 update test runtime secrets for courseplatform"
git push
./scripts/secrets/edit_runtime_secret_set.sh cleanup test courseplatform
```

### 4) Commit and push

```bash
git add secrets/runtime/test/courseplatform.app.env.enc secrets/runtime/test/courseplatform.postgres.env.enc
git commit -m "CP-56 add encrypted test runtime secrets for courseplatform"
git push
```

## Automatic sync on push

Workflow `.github/workflows/sync-runtime-secrets.yml` runs automatically on pushes to `main` when encrypted runtime files change under:

- `secrets/runtime/test/*.enc`
- `secrets/runtime/prod/*.enc`

Behavior:

1. Detects exactly which `environment/app` pairs changed.
2. Decrypts only those files with `SOPS_AGE_KEY`.
3. Syncs to matching host over Tailscale SSH.
4. If app env changed (`*.app.env.enc`), performs rolling app container reload.
5. If postgres env changed (`*.postgres.env.enc`), updates file only (no auto Postgres restart).

You can still run it manually via `workflow_dispatch` for forced re-sync.

Merge guard:

- `.github/workflows/runtime-secrets-guard.yml` validates that every touched `env/app` pair has both encrypted files present:
  - `<app>.app.env.enc`
  - `<app>.postgres.env.enc`

## Verification

```bash
ssh -o ProxyCommand='tailscale nc %h %p' root@susanoo-test "sudo stat -c '%a %n' /srv/apps/courseplatform/.env /srv/postgres/courseplatform.env"
```

Expected permissions:

- `600 /srv/apps/courseplatform/.env`
- `600 /srv/postgres/courseplatform.env`

## Rollout note

Runtime secret file updates do not automatically recreate app containers.

App secret updates now trigger rolling reload automatically.

## Postgres credential caveat

For existing initialized Postgres volumes, changing `POSTGRES_USER` or `POSTGRES_PASSWORD` in env files does not rotate credentials inside the database automatically.

Safe rule:

- Keep Postgres credentials stable once initialized.
- If rotation is needed, run an explicit SQL credential-rotation procedure first, then update encrypted env files and redeploy.
