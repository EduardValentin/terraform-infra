# Tailscale Tags and ACL Baseline

Primary management path: `infra/envs/controlplane` Terraform root with the `tailscale_acl` resource.
Adjust policy inputs through `tailscale_*` variables and apply from that environment.

This document records policy intent and invariants. It does not duplicate the generated ACL JSON.

## Source of Truth

- Policy assembly: `infra/envs/controlplane/main.tf`, `local.tailscale_policy`
- Policy inputs and defaults: `infra/envs/controlplane/variables.tf`
- Example override payload: `infra/envs/controlplane/terraform.tfvars.example`
- Applied resource: `infra/envs/controlplane/main.tf`, `tailscale_acl.policy`
- Rendered policy for review:

```bash
terraform -chdir=infra/envs/controlplane output -raw tailscale_policy_json | jq .
```

Actual identities and destinations come from `TFVARS_CONTROLPLANE` at apply time.

## Policy invariants

- Admin reachability remains global:
  - `tailscale_admin_destinations` should stay `[*:*]` so admins can still reach untagged devices.
- Admin Tailscale SSH includes `autogroup:self` so an admin can SSH to their own user-owned, untagged devices after those devices advertise Tailscale SSH locally.
- OpenCL account remains scoped:
  - it is limited to explicit TEST and OPS service ports
  - it must not receive SSH access
- OpenCL node identity remains scoped:
  - the OpenCL agent tag may reach only explicit TEST and OPS service ports
  - it must not receive SSH access to TEST or OPS nodes
- Regular member reachability is controlled only by:
  - `tailscale_regular_member_sources`
  - `tailscale_regular_member_destinations`
- CI identities stay split by function:
  - Terraform CI reaches only the Terraform backend path
  - runtime-secret CI reaches only host SSH paths needed for secret sync
  - app-deploy CI reaches only host SSH paths needed for app deploys
- Long-lived host bootstrap keeps using reusable pre-auth keys only for first join and recovery.

## Current intent

- CI workflows mint ephemeral Tailscale auth through OAuth client credentials.
- Long-lived VMs do not use OAuth for steady-state connectivity.
- The app-deploy CI tag is the current deploy tag for the existing app deployment path.
- CI SSH workflows resolve the current target IP from `tailscale status --json`; ACL reachability is still governed by the stable node hostname/tag pair, not by a static SSH target secret.
- If multiple app repos later share the same host model, either keep a shared deploy tag intentionally or redesign host-side permissions before splitting per-app tags.
