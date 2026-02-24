# YAI Infra - Factory & Governance Toolkit

`yai-infra` is the open factory window for YAI: the canonical place for standards, automation, and enforcement across the YAI ecosystem.

It exists so contributors and reviewers can see exactly how we work, and so all repos can consume a single, consistent governance toolchain.

## What This Repo Is

- Standards: repo layout, naming, branch/PR discipline, CI gates, documentation residency rules
- Governance automation: GitHub templates, labeling, project sync, PR enforcement
- Reusable GitHub Actions: shared governance suite consumed by `yai`, `yai-cli`, and `yai-law`
- Tooling: verified scripts and Python modules for validation, syncing, and evidence generation

## What This Repo Is Not

- Not the YAI runtime product
- Not shipped as part of the customer-facing bundle (`yai` + `yai-cli` + `yai-law`)
- Not a place for runtime architecture docs or program decisions (those live in `yai`)

## Quick Links

- Standards: `docs/standards/README.md`
- Tooling manual: `docs/tooling/README.md`
- Canonical GitHub templates policy: `governance/templates/github/README.md`

## Repository Layout

- `docs/standards/` - company-grade rules (residency, template policy, project automation)
- `docs/tooling/` - how to run the factory (toolkit contract, governance suite, actions suite)
- `governance/templates/github/` - canonical GitHub templates source of truth
- `tools/bin/` - executable entrypoints (`yai-*`)
- `tools/python/` - Python packages powering the toolkit
- `tools/ops/` - operational scripts (suite, gates, verification)
- `migration/` - inventory and cutover plans (non-product)

## Getting Started (Local)

Prerequisites:
- Python 3.x (matching your repo toolchain)
- A GitHub token only if you use project automation features (optional)

Run basic info:

```bash
./tools/bin/yai-version
```

See available commands:

```bash
ls ./tools/bin
```

## Consuming Governance From Other Repos

### 1) GitHub Actions governance suite (reusable)

Consumer repos should keep thin wrapper workflows that call the infra suite.

Example:

```yaml
jobs:
  governance:
    uses: yai-labs/yai-infra/.github/workflows/reusable-governance-suite.yml@main
    secrets: inherit
```

After stabilization, consumers should pin to a tag instead of `main`.

### 2) GitHub templates are mirrored (managed)

Templates must be identical across consumer repos and treated as managed mirror.

Canonical scope:
- `.github/ISSUE_TEMPLATE/**`
- `.github/PULL_REQUEST_TEMPLATE/**`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/labeler.yml`

Mirror/check drift:

```bash
./tools/sh/sync_github_templates.sh sync  --target ../yai
./tools/sh/sync_github_templates.sh check --target ../yai
```

## Toolkit Commands (High Signal)

Common entrypoints in `tools/bin/`:

- `yai-verify` - verification suite (repo checks/gates)
- `yai-suite` - higher-level suite execution
- `yai-docs-trace-check` - docs traceability validation
- `yai-proof-check` - proof/evidence validation
- `yai-check-pins` - pin integrity checks
- `yai-law-sync` - sync/update law references (canonical)
- `yai-specs-sync` - legacy compatibility stub (deprecated)

## Versioning

- Toolkit version is tracked in `tools/VERSION`
- Governance suite should be tagged when stable so consumers can pin deterministically

## Contributing

This repo is intended to be readable and operational.

Start with:
- `docs/standards/README.md`
- `docs/tooling/README.md`

PRs should be small and scoped, and include verification output when changing enforcement.
