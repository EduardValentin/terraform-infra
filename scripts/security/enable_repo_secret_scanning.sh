#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <owner/repo> [owner/repo ...]"
  exit 1
fi

for repo in "$@"; do
  echo "enabling secret scanning + push protection for $repo"

  if gh api -X PATCH "repos/$repo" \
    -f 'security_and_analysis[secret_scanning][status]=enabled' \
    -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled' \
    --silent; then
    gh api "repos/$repo" --jq '.security_and_analysis'
  else
    echo "failed to enable for $repo (repository plan/features may not support this)"
  fi
done
