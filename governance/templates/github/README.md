# GitHub Templates Canonical Source

This directory is the source of truth for GitHub issue/PR templates and label rules used across the YAI ecosystem.

Canonical tree:

- `governance/templates/github/.github/ISSUE_TEMPLATE/*`
- `governance/templates/github/.github/PULL_REQUEST_TEMPLATE/*`
- `governance/templates/github/.github/PULL_REQUEST_TEMPLATE.md`
- `governance/templates/github/.github/labeler.yml`
- `governance/templates/github/.github/.managed-by-yai-infra`

Repository mirror files under `.github/*` are generated from this canonical source.

Sync/check:

- sync mirror: `tools/sh/sync_github_templates.sh sync --target <path-to-repo>`
- verify no drift: `tools/sh/sync_github_templates.sh check --target <path-to-repo>`
