# Secrets

Store encrypted secret files only.

## bootstrap secret file

1. Create plaintext temp file outside this repository.
2. Encrypt with SOPS using age:

```bash
sops --encrypt --input-type yaml --output-type yaml /tmp/bootstrap.yaml > /Users/trocaneduard/Documents/Personal/terraform-infra/secrets/bootstrap.enc.yaml
```

3. Remove plaintext temp file.

Suggested structure:

```yaml
tailscale:
  auth_key_test: tskey-...
  auth_key_prod: tskey-...
  auth_key_ops: tskey-...
cloudflare:
  zone_id: xxxxx
```
