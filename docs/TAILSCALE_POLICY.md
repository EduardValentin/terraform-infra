# Tailscale Tags and ACL Baseline

Primary management path: `infra/envs/controlplane` Terraform root with the `tailscale_acl` resource.
Adjust policy inputs through `tailscale_*` variables and apply from that environment.

This document describes the current policy shape and the intended invariants.
Actual identities and destinations come from `TFVARS_CONTROLPLANE`.

```json
{
  "tagOwners": {
    "tag:prod": ["group:admin"],
    "tag:test": ["group:admin"],
    "tag:ops": ["group:admin"],
    "tag:solus-agent": ["group:admin"],
    "tag:ci-app-deploy": ["group:admin"],
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
      "src": ["tag:ci-app-deploy"],
      "dst": ["tag:test:22", "tag:prod:22"]
    },
    {
      "action": "accept",
      "src": ["tag:ops"],
      "dst": [
        "tag:test:443",
        "tag:test:8080",
        "tag:test:9100",
        "tag:prod:443",
        "tag:prod:8080",
        "tag:prod:9100"
      ]
    },
    {
      "action": "accept",
      "src": ["tag:test", "tag:prod"],
      "dst": ["tag:ops:3100", "tag:ops:4317", "tag:ops:4318"]
    },
    {
      "action": "accept",
      "src": ["<opencl-account-source>"],
      "dst": [
        "tag:test:443",
        "tag:test:8080",
        "tag:test:9100",
        "tag:ops:3000",
        "tag:ops:9090",
        "tag:ops:3100",
        "tag:ops:3200",
        "tag:ops:4317",
        "tag:ops:4318",
        "tag:ops:18080",
        "tag:ops:19100"
      ]
    },
    {
      "action": "accept",
      "src": ["tag:solus-agent"],
      "dst": [
        "tag:test:443",
        "tag:test:8080",
        "tag:test:9100",
        "tag:ops:3000",
        "tag:ops:9090",
        "tag:ops:3100",
        "tag:ops:3200",
        "tag:ops:4317",
        "tag:ops:4318",
        "tag:ops:18080",
        "tag:ops:19100"
      ]
    },
    {
      "action": "accept",
      "src": ["<opencl-admin-source>"],
      "dst": ["tag:solus-agent:*"]
    },
    {
      "action": "accept",
      "src": ["<regular-member-source>"],
      "dst": ["*:*"]
    },
    {
      "action": "accept",
      "src": ["group:admin"],
      "dst": ["*:*"]
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
      "src": ["tag:ci-app-deploy"],
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

## Policy invariants

- Admin reachability remains global:
  - `tailscale_admin_destinations` should stay `[*:*]` so admins can still reach untagged devices.
- OpenCL account remains scoped:
  - it is limited to explicit TEST and OPS service ports
  - it must not receive SSH access
- OpenCL node identity remains scoped:
  - `tag:solus-agent` may reach only explicit TEST and OPS service ports
  - it must not receive SSH access to TEST or OPS nodes
- Regular member reachability is controlled only by:
  - `tailscale_regular_member_sources`
  - `tailscale_regular_member_destinations`
- CI identities stay split by function:
  - `tag:ci-terraform` reaches only the OPS MinIO backend
  - `tag:ci-secrets` reaches only TEST and PROD SSH for runtime secret sync
  - `tag:ci-app-deploy` currently reaches only TEST and PROD SSH for app deploy workflows
- Long-lived host bootstrap keeps using reusable pre-auth keys for:
  - `tag:test`
  - `tag:ops`
  - `tag:prod`

## Current intent

- CI workflows mint ephemeral Tailscale auth through OAuth client credentials.
- Long-lived VMs do not use OAuth for steady-state connectivity.
- `tag:ci-app-deploy` is the current deploy tag for the existing app deployment path.
- CI SSH workflows resolve the current target IP from `tailscale status --json`; ACL reachability is still governed by the stable node hostname/tag pair, not by a static SSH target secret.
- If multiple app repos later share the same host model, either keep a shared deploy tag intentionally or redesign host-side permissions before splitting per-app tags.
