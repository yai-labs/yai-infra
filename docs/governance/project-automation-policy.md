# Project Automation Policy

This policy defines canonical automation behavior for `YAI Infra Governance`
Project (Project v2 #5), and is designed for reuse in other YAI projects.

## Required automatic fields

- `Status`: `In Progress` while open, `Done` when closed/merged.
- `Gate Status`: `Running` while open, `Passed` when closed/merged,
  `Failed` for closed-unmerged PRs.
- `Phase`: from milestone token `0.x.y`, fallback to default configured phase.
- `Track`: from `track:*` labels, fallback to configured default track.
- `Work Type`: `Issue` / `PR`.
- `Type`: mirrors `Work Type` when field exists in target project.
- `Phase Type`: `Execution Issue` / `PR` by item type.
- `Class`: deterministic A/B classification policy.
- `Target Date`:
  - Open item: milestone due date only.
  - Closed/Merged item: close/merge date first, fallback milestone due date.
  - If no date source exists: clear field.

## Label governance

- Canonical labels and colors are created/enforced automatically.
- Type labels (`type:*`) and track labels (`track:*`) are inferred from title/body
  and normalized on intake and backfill.

## Retroactive backfill

- A dedicated workflow (`project-backfill-sync`) repairs historical drift:
  labels, assignee, and all project fields including `Type` and `Target Date`.
