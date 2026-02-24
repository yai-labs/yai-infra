# GitHub Templates Standard

## Canonical source

`yai-infra` is the source of truth for templates and labels.

Canonical source path:

- `governance/templates/github/.github/*`

## Mirror scope

- `.github/ISSUE_TEMPLATE/**`
- `.github/PULL_REQUEST_TEMPLATE/**`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/labeler.yml`
- `.github/.managed-by-yai-infra`

## Rules

1. `yai-infra` is source of truth.
2. Consumer repositories keep mirror files only.
3. Change templates only in `yai-infra`.
4. Sync mirrors with `sync --target`.
5. Drift checks (`check --target`) are hard-fail in CI.
