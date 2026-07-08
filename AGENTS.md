## Ticket system and project

Use Linear for infrastructure repository work.

- Team: `General Hub`
- Linear project: `Infrastructure`
- Ticket key format follows the Linear issue identifier, for example `GEN-107`.

Do not file infrastructure, bootstrap, operations, Terraform, Tailscale, CI/CD, secret-sync, observability, backup, or host-maintenance work under application projects such as `Course Platform`.

## Mandatory ticket based delivery workflow

Use this when the work is associated with a ticket.

1. Pick a ticket key (example: `GEN-107`).
2. Move ticket to `In Progress`.
3. Add a short Linear comment describing planned approach.
4. Create a branch from `main`.
5. Implement changes with tests/validation.
6. Commit with one-line messages.
7. Push branch and create a PR.
8. Add a Linear comment with PR link, what changed, validation, and remaining work.

## Branch and PR naming

- Branch name format:
  - `<ticket-key>-<short-slug>`
  - Example: `gen-107-test-docker-cleanup`
- PR title must include ticket key.
  - Example: `[GEN-107] Add TEST Docker image cleanup`

## Validation rules

Before PR, run relevant checks and report results in PR body.

At minimum where applicable:

- shell syntax checks for bootstrap scripts
- bundle packaging check (`scripts/package_bootstrap_bundle.sh <version>`)
- Terraform format/validate where available

If a check cannot run, explicitly state why and what is needed.

## Security and operations rules

- Never commit plaintext secrets.
- Use SOPS+age for encrypted secret files.
- Keep host bootstrap idempotent.
- Keep deploy artifacts versioned and immutable.
- Preserve standardized labels: `env`, `app`, `service`, `host`.
- Do not add high-cardinality PII labels to Loki.
- Do not introduce public admin access paths that violate charter constraints.
- Keep Tailscale auth model consistent:
  - CI workflows use OAuth secrets (`TAILSCALE_OAUTH_CLIENT_ID`, `TAILSCALE_OAUTH_SECRET`).
  - Long-lived VMs use bootstrap auth keys only for first join/recovery (`bootstrap_tailscale_auth_key_*` in control-plane tfvars).
  - Do not reintroduce static CI auth keys for app or infra workflows.

## Documentation sync rules

Do not keep duplicated information in the docs by pasting code or configuration file in docs. Prefer referencing to the file containing the code with configuration code instead.
Keep the docs updated only when the repository architecture changes or when we add or update different concerns. Docs must not be updated on every configuration change.
Docs must explain the repository and the approaches it takes and responsabilities it has, not document every configuration in it.

## Scope discipline

This repo is for infrastructure and operations delivery only.

Do not put application business logic here.

When app changes are needed, create or reference the corresponding ticket in the application repository and link both tickets in Linear comments.

## Done criteria for an agent task

A task is done only when all are true:

- code is pushed in a ticket-linked branch
- PR is open with required sections
- validation evidence is included
- remaining work is explicitly listed
