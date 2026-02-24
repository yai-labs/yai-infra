# GitHub Template Residency

Canonical GitHub templates for YAI repositories are owned by `yai-infra`
under:

- `governance/templates/github/.github/*`

Mirror files used by GitHub UX are generated from canonical source:

- `.github/ISSUE_TEMPLATE/*`
- `.github/PULL_REQUEST_TEMPLATE/*`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/.managed-by-yai-infra`

Consumer repositories may keep local copies only as mirrors for GitHub UX
compatibility. Mirror drift is not allowed and must be enforced by CI checks
against `yai-infra` canonical templates.

Local sync/check commands:

- `tools/sh/sync_github_templates.sh sync`
- `tools/sh/sync_github_templates.sh check`
