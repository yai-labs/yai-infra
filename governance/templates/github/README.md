# GitHub Templates Canonical Source

This directory is the source of truth for GitHub issue/PR templates used across the YAI ecosystem.

Canonical tree:

- `governance/templates/github/.github/ISSUE_TEMPLATE/*`
- `governance/templates/github/.github/PULL_REQUEST_TEMPLATE/*`
- `governance/templates/github/.github/PULL_REQUEST_TEMPLATE.md`

Repository mirror files under `.github/*` are generated from this canonical source.

Sync/check:

- apply mirror update: `tools/sh/sync_github_templates.sh`
- verify no drift: `tools/sh/sync_github_templates.sh --check`
