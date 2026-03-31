# Runtime Secrets Management (SOPS + age)

This is the primary runtime secret workflow for TEST and PROD.

## Design

1. Runtime secrets are committed encrypted in this repository.
2. Decryption happens only in GitHub Actions using `SOPS_AGE_KEY`.
3. CI syncs decrypted files to hosts over Tailscale SSH.
4. Hosts keep runtime secrets locally at:
   - `/srv/apps/<app>/.env`
   - `/srv/postgres/<app>.env`

Normal operations should not require manual secret edits on the VM shell.

Plaintext authoring workspace:

- `secrets/runtime/work/` is gitignored and is the only intended local plaintext workspace.

Helper script:

- `scripts/secrets/edit_runtime_secret_set.sh`
  - `prepare`: decrypt into the gitignored work folder, or seed from templates if encrypted files do not exist yet
  - `apply`: encrypt edited work files back into `secrets/runtime/<env>/`
  - `cleanup`: remove the local plaintext work folder

## One-time setup

### 1) Install local tools

```bash
brew install sops age
```

### 2) Generate an age keypair

```bash
mkdir -p "$HOME/.config/sops/age"
age-keygen -o "$HOME/.config/sops/age/keys.txt"
```

Extract the public key:

```bash
grep '^# public key:' "$HOME/.config/sops/age/keys.txt" | awk '{print $4}'
```

### 3) Configure `.sops.yaml`

Set the real age public key in `.sops.yaml`.

### 4) Configure GitHub secrets

In `terraform-infra`, set:

- `SOPS_AGE_KEY`: the full private key content from `$HOME/.config/sops/age/keys.txt`
- `TAILSCALE_OAUTH_CLIENT_ID`
- `TAILSCALE_OAUTH_SECRET`
- `TEST_SSH_KNOWN_HOSTS`
- `PROD_SSH_KNOWN_HOSTS`
- repository variable `TEST_NODE_HOSTNAME`
- repository variable `PROD_NODE_HOSTNAME`

## Standard editing cycle

### Create or update a secret set

Prepare files for an app and environment:

```bash
./scripts/secrets/edit_runtime_secret_set.sh prepare test courseplatform
```

Edit the resulting plaintext files in:

- `secrets/runtime/work/test-courseplatform/courseplatform.app.env`
- `secrets/runtime/work/test-courseplatform/courseplatform.postgres.env`

If encrypted files do not exist yet, `prepare` seeds the work directory from templates.

Encrypt the updated files back into the repository:

```bash
./scripts/secrets/edit_runtime_secret_set.sh apply test courseplatform
```

Then commit and push the encrypted outputs:

```bash
git add secrets/runtime/test/courseplatform.app.env.enc secrets/runtime/test/courseplatform.postgres.env.enc
git commit -m "Update runtime secrets for courseplatform"
git push
```

Remove the local plaintext work files when done:

```bash
./scripts/secrets/edit_runtime_secret_set.sh cleanup test courseplatform
```

## Automatic sync on push

`.github/workflows/sync-runtime-secrets.yml` runs automatically on pushes to `main` when encrypted runtime files change under:

- `secrets/runtime/test/*.enc`
- `secrets/runtime/prod/*.enc`

Behavior:

1. Detects exactly which `environment/app` pairs changed.
2. Decrypts only those files with `SOPS_AGE_KEY`.
3. Resolves the matching host's current Tailscale IP from `tailscale status --json`.
4. Syncs them to the matching host over Tailscale SSH with strict host key checking.
5. If `*.app.env.enc` changed, performs a rolling app container reload.
6. If `*.postgres.env.enc` changed, updates the file only and does not restart Postgres automatically.

You can also run the workflow manually with `workflow_dispatch`.

Merge guard:

- `.github/workflows/runtime-secrets-guard.yml` requires both encrypted files for each touched `env/app` pair:
  - `<app>.app.env.enc`
  - `<app>.postgres.env.enc`

## Verification

```bash
ssh -o ProxyCommand='tailscale nc %h %p' root@susanoo-test "sudo stat -c '%a %n' /srv/apps/courseplatform/.env /srv/postgres/courseplatform.env"
```

Expected permissions:

- `600 /srv/apps/courseplatform/.env`
- `600 /srv/postgres/courseplatform.env`

## Postgres credential caveat

For an already initialized Postgres volume, changing `POSTGRES_USER` or `POSTGRES_PASSWORD` in env files does not rotate credentials inside the database.

Safe rule:

- keep Postgres credentials stable once initialized
- if rotation is needed, run an explicit SQL credential rotation procedure first, then update encrypted env files and redeploy
