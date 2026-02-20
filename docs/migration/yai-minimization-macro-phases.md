# YAI Minimization Macro Phases

This runbook defines how to minimize `yai` to runtime/core scope and migrate non-core assets into `yai-infra`.

## Phase A: Inventory and Classification
- Build path-level inventory for `yai` non-core candidates (tooling, governance docs, templates, policy assets).
- Classify each path as `move`, `deprecate`, or `keep`.
- Assign ownership (`infra` vs `runtime`).

## Phase B: Infra Import (Control-Plane First)
- Import non-core assets into `yai-infra` with stable paths.
- Preserve history and provenance references.
- Add compatibility notes and migration index docs.

## Phase C: YAI Cleanup (Minimal Surface)
- Remove moved non-core assets from `yai`.
- Keep thin wrappers only where compatibility is required.
- Ensure runtime/core directories remain untouched.

## Phase D: CI and Policy Hardening
- Rewire any remaining governance checks to `yai-infra` reusable workflows/tools.
- Validate metadata, changelog, and project-sync automation.
- Ensure no duplicate governance sources remain in `yai`.

## Phase E: Stabilization and Closure
- Validate CI parity on all affected repos.
- Update rollback notes and closure evidence.
- Close hardening issue only after move-map and cleanup PRs are merged.

## Current Phase
- **In progress:** Phase A -> B transition for issue `yai-infra#17`.
