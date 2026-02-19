# Tailscale Tags and ACL Baseline

Primary management path: `infra/envs/controlplane` Terraform root with `tailscale_acl` resource.
Adjust policy inputs through Terraform variables (`tailscale_*`) and apply from that environment.

```json
{
  "tagOwners": {
    "tag:prod": ["group:admin"],
    "tag:test": ["group:admin"],
    "tag:ops": ["group:admin"],
    "tag:ci-courseplatform": ["group:admin"],
    "tag:ci-secrets": ["group:admin"],
    "tag:ci-terraform": ["group:admin"]
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
      "src": ["group:admin"],
      "dst": ["tag:prod:*", "tag:test:*", "tag:ops:*"]
    }
  ],
  "ssh": [
    {
      "action": "accept",
      "src": ["group:admin"],
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

Use separate reusable pre-auth keys restricted to each CI tag.

- `tag:ci-terraform`: terraform plan/apply (OPS MinIO backend only)
- `tag:ci-secrets`: runtime secret sync workflows (SSH to TEST/PROD only)
- `tag:ci-courseplatform`: application deployment workflows (SSH to TEST/PROD only)
