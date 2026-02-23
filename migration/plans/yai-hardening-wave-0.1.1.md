# YAI Hardening Wave 0.1.1

Tracking issue: `yai-infra#17`

## Objective
Reduce `yai` repository surface to runtime/core scope and move non-core governance/process/tooling/docs to `yai-infra`.

## Wave Scope (Concrete)
- Move from `yai` to `yai-infra`:
  - `tools/python/yai_tools/**`
  - governance-oriented tooling entrypoints from `tools/bin/**`
  - `tools/ops/**` (cross-repo operational suite)
  - `tools/release/**`, `tools/data/**`, `tools/dev/**`, `tools/bundle/**`
  - `tools/schemas/docs/**`
  - `docs/dev-guide/**`, `docs/templates/**`, `docs/_policy/**`, `docs/proof/**`
- Keep in `yai`:
  - runtime core code and runtime-specific docs
  - thin compatibility wrappers under `tools/bin` where required

## Execution Steps
1. Import paths into `yai-infra` with structure + ownership docs.
2. Update move-map with path-level rules and risk tags.
3. Open cleanup PR in `yai` removing migrated assets.
4. Add compatibility wrappers in `yai` for transition commands.
5. Run CI and verify no governance duplication remains.

## Acceptance
- [x] `yai-infra` contains canonical governance/process/tooling/docs moved from `yai` (wave2 tools import in progress)
- [x] `yai` non-core assets removed or wrapped (ops/release/data/dev/bundle wrapperized)
- [ ] `yai` CI green after cleanup
- [ ] rollback guidance updated

## Tooling Externalization (bin/python)

- Canonical governance tooling moved to `yai-infra/tools/bin` and `yai-infra/tools/python/yai_tools`.
- Canonical non-core tooling moved to `yai-infra/tools/{ops,release,data,dev,bundle}`.
- `yai` keeps compatibility wrappers that delegate to infra canonical paths.
- Next step: execute CI parity checks and then remove stale mirrors once consumer repos are pinned.
