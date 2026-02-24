# Governance Suite (Reusable Orchestrator)

The canonical one-call governance orchestrator is:

- `.github/workflows/reusable-governance-suite.yml`

It allows consumer repositories to keep a single wrapper workflow for PR governance enforcement.

## Inputs

- `org` (default: `yai-labs`)
- `project_number`
- `enable_project_sync` (default: `true`)
- `enable_template_verify` (default: `true`)
- `dry_run` (default: `false`)

## What it orchestrates

For PR events, the suite runs in sequence:

1. PR context extraction
2. PR auto-label
3. PR metadata validation
4. changelog validation
5. PR issue-link enforcement
6. PR milestone sync
7. project intake sync (optional)
8. project status sync on close (optional)
9. canonical template drift verify (optional)
10. governance verify

## Consumer usage (minimal wrapper)

```yaml
name: governance-pr

on:
  pull_request:
    types: [opened, edited, synchronize, reopened, ready_for_review, closed]

jobs:
  governance:
    uses: yai-labs/yai-infra/.github/workflows/reusable-governance-suite.yml@main
    with:
      org: yai-labs
      project_number: 2
      enable_project_sync: true
      enable_template_verify: true
      dry_run: false
    secrets: inherit
```
