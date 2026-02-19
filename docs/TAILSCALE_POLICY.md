# Tailscale Tags and ACL Baseline

Primary management path: `infra/envs/controlplane` Terraform root with `tailscale_acl` resource.
Adjust policy inputs through Terraform variables (`tailscale_*`) and apply from that environment.

```json
{
  "tagOwners": {
    "tag:prod": ["autogroup:admin"],
    "tag:test": ["autogroup:admin"],
    "tag:ops": ["autogroup:admin"],
    "tag:ci-courseplatform": ["autogroup:admin"],
    "tag:ci-secrets": ["autogroup:admin"],
    "tag:ci-terraform": ["autogroup:admin"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["tag:ci-terraform"],
      "dst": ["tag:ops:9000"]
    },
    {
      "action": "accept",
      "src": ["tag:ci-secrets"],
      "dst": ["tag:test:22", "tag:prod:22"]
    },
    {
      "action": "accept",
      "src": ["tag:ci-courseplatform"],
      "dst": ["tag:test:22", "tag:prod:22"]
    },
    {
      "action": "accept",
      "src": ["eli.lungu04@gmail.com"],
      "dst": ["*:*"]
    },
    {
      "action": "accept",
      "src": ["autogroup:admin"],
      "dst": ["tag:prod:*", "tag:test:*", "tag:ops:*"]
    }
  ],
  "ssh": [
    {
      "action": "accept",
      "src": ["autogroup:admin"],
      "dst": ["tag:prod", "tag:test", "tag:ops"],
      "users": ["root", "ubuntu"]
    },
    {
      "action": "accept",
      "src": ["tag:ci-courseplatform"],
      "dst": ["tag:test", "tag:prod"],
      "users": ["root"]
    },
    {
      "action": "accept",
      "src": ["tag:ci-secrets"],
      "dst": ["tag:test", "tag:prod"],
      "users": ["root"]
    }
  ]
}
```

CI access model:

- CI workflows mint ephemeral Tailscale auth via OAuth client credentials.
- Required OAuth tags:
  - `tag:ci-terraform`: terraform plan/apply (OPS MinIO backend only)
  - `tag:ci-secrets`: runtime secret sync workflows (SSH to TEST/PROD only)
  - `tag:ci-courseplatform`: application deployment workflows (SSH to TEST/PROD only)

Server bootstrap model:

- Keep reusable pre-auth keys for server bootstrap/recovery only:
  - `tag:test`
  - `tag:ops`
  - `tag:prod`
