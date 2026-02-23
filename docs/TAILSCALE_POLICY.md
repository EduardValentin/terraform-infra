# Tailscale Tags and ACL Baseline

Primary management path: `infra/envs/controlplane` Terraform root with `tailscale_acl` resource.
Adjust policy inputs through Terraform variables (`tailscale_*`) and apply from that environment.

```json
{
  "tagOwners": {
    "tag:prod": ["group:admin"],
    "tag:test": ["group:admin"],
    "tag:ops": ["group:admin"],
    "tag:solus-agent": ["group:admin"],
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
      "src": ["solus.assistant@gmail.com"],
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
      "src": ["eduard.valentin1996@gmail.com"],
      "dst": ["tag:solus-agent:*"]
    },
    {
      "action": "accept",
      "src": ["eli.lungu04@gmail.com"],
      "dst": ["tag:test:*", "tag:ops:*", "tag:prod:*"]
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

OpenCL access model:

- `tailscale_opencl_agent_tag` defaults to `tag:solus-agent`; join the OpenCL VM with this tag.
- `tailscale_opencl_agent_tag_owners` controls who can advertise/assign the OpenCL agent tag (default includes `solus.assistant@gmail.com`, plus admin group).
- `tailscale_opencl_account_sources` and `tailscale_opencl_account_destinations` limit what the OpenCL account can see/reach (default: only TEST/OPS service ports, no SSH access).
- `tailscale_opencl_agent_sources` and `tailscale_opencl_agent_destinations` control what the OpenCL agent node can reach (default: `tag:solus-agent` to explicit TEST/OPS service ports only, no SSH access).
- `tailscale_opencl_admin_sources` and `tailscale_opencl_admin_destinations` control who can reach OpenCL VM services (default: `eduard.valentin1996@gmail.com` to `tag:solus-agent:*`).

Desired behavior invariants (do not change without explicit owner approval):

- Admin reachability is global:
  - `tailscale_admin_destinations` must remain `["*:*"]` so admin can still access untagged tailnet devices.
- OpenCL account is scoped:
  - `solus.assistant@gmail.com` must be limited to TEST/OPS service ports only.
  - OpenCL account must not have SSH access (no `:22`, no `ssh` rule for this account).
- OpenCL node identity is scoped:
  - `tag:solus-agent` may reach only TEST/OPS service ports.
  - `tag:solus-agent` must not have SSH access to TEST/OPS nodes.
- Tag assignment guard:
  - `solus.assistant@gmail.com` must remain allowed in `tailscale_opencl_agent_tag_owners` so the agent VM can join with `tag:solus-agent`.
- Access expectations:
  - `eduard.valentin1996@gmail.com` can access `tag:solus-agent:*` from any personal device in the same tailnet.
  - `https://solus-pc.longhair-eagle.ts.net/` is expected to work when `solus-pc` is online, logged in, tagged as `tag:solus-agent`, and `tailscale serve` is active.

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
