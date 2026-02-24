# GitHub Actions Governance Suite (Canonical)

`yai-infra` is the source of truth for governance workflows consumed by YAI repositories.

## Canonical reusable workflows (`workflow_call`)

- `reusable-auto-label-issue.yml`: infer/apply canonical labels for issues.
- `reusable-auto-label-pr.yml`: enforce canonical labels for pull requests.
- `reusable-pr-issue-enforcement.yml`: enforce PR issue-link policy.
- `reusable-pr-milestone-sync.yml`: sync PR milestone from linked issue.
- `reusable-project-intake-sync.yml`: intake automation for Project v2 fields and labels.
- `reusable-project-status-sync.yml`: close/merge status sync for PR items.
- `reusable-project-backfill-sync.yml`: retroactive drift repair for project items.
- `reusable-verify-github-templates.yml`: verify consumer `.github` templates against canonical infra templates.
- `reusable-validate-pr-metadata.yml`: validate PR metadata contract.
- `reusable-validate-changelog.yml`: validate changelog gate.
- `reusable-verify.yml`: generic governance verification wrapper.
- `reusable-governance-suite.yml`: optional orchestrator for validate -> verify -> sync chains.

## Reusable contract

Standard inputs (shared by suite):

- `org` (string)
- `project_number` (number)
- `repo_scope` (string, optional)
- `dry_run` (boolean, optional)

Standard secret contract:

- consumer uses `secrets: inherit`
- reusable may optionally consume `project_token` (fallback remains `GITHUB_TOKEN` where applicable)

## Consumer pattern

Consumer repos keep thin wrappers only:

- trigger (`on:`)
- `uses: yai-labs/yai-infra/.github/workflows/<reusable>.yml@<ref>`
- `with:` inputs
- `secrets: inherit`

No governance logic should be duplicated in consumer workflows.

## Permissions model

- `GITHUB_TOKEN`: default for repository-scoped reads/writes (labels, PR metadata, basic checks).
- PAT/App token (`project_token`): required for Project v2 GraphQL mutations when org/project permissions exceed default token scope.

## Reference

- Canonical template residency: `docs/governance/github-template-residency.md`
- Project automation policy: `docs/governance/project-automation-policy.md`

## Project Workflows Baseline (GitHub Projects)

For each governed project board (e.g. Program Delivery, Infra Governance), enable:

- Auto-add sub-issues to project
- Pull request linked to issue
- Pull request merged
- Item closed
- Item added to project

Field normalization remains action-driven via reusable project sync workflows:

- `reusable-project-intake-sync.yml`
- `reusable-project-status-sync.yml`
- `reusable-project-backfill-sync.yml`
