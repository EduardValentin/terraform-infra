# Agent Workflow Contract

This file defines how coding agents must operate in this repository.

## Source of truth

Before starting any work, read:

- `docs/REPOSITORY_CHARTER.md`

The charter contains architecture intent, constraints, environment model, portability rules, scaling plan, and operating guidance.

If this file and the charter conflict, follow the charter and update this file in the same PR.

## Mandatory delivery workflow

Every unit of work must be tied to a Jira ticket.

1. Pick a ticket key (example: `CP-123`).
2. Move ticket to `In Progress`.
3. Add a short Jira comment describing planned approach.
4. Create a branch from `main`.
5. Implement changes with tests/validation.
6. Commit with one-line messages.
7. Push branch and create a PR.
8. Add a Jira comment with PR link, what changed, validation, and remaining work.
9. Keep ticket status aligned with reality.

No ticket means no code changes.

## Branch and PR naming

- Branch name format:
  - `codex/<ticket-key>-<short-slug>`
  - Example: `codex/cp-123-ops-retention-tuning`
- PR title must include ticket key.
  - Example: `[CP-123] Tune Loki and Tempo retention settings`

## PR requirements

Every PR description must include these sections:

1. `Intention`
2. `Implementation Details and Decisions`
3. `What Remains Next`
4. `Manual Testing Instructions`

Always explain:

- what changed
- why it changed
- what is still pending

If scope changed from ticket intent, explain why and update Jira comment.

## Commit rules

- One-line commit messages only.
- Include ticket key when possible.
- Keep message descriptive enough to understand later.
- Avoid vague commits like `fix stuff`.

Examples:

- `CP-123 add ops low-resource tempo config`
- `CP-123 generate traefik tls dynamic file from tailscale hostnames`

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

## Scope discipline

This repo is for infrastructure and operations delivery only.

Do not put application business logic here.

When app changes are needed, create or reference the corresponding ticket in the application repository and link both tickets in Jira comments.

## Ticket communication checklist

At minimum, leave these Jira comments:

1. Start comment:
   - plan
   - risks
   - expected deliverables
2. PR comment:
   - PR URL
   - validations run
   - known limitations
3. Completion comment:
   - final summary
   - follow-up tasks

## Done criteria for an agent task

A task is done only when all are true:

- code is pushed in a ticket-linked branch
- PR is open with required sections
- Jira contains status and comments
- validation evidence is included
- remaining work is explicitly listed
