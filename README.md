# yai-infra

yai-infra is the governance control-plane for the YAI ecosystem.

It hosts: policy, reusable workflows, enforcement tooling, runbooks, and cross-repo documentation.
Core repos (yai, yai-cli, yai-mind, etc.) stay product-focused and consume yai-infra via version pin (tag/SHA).
No copy-paste of workflows and scripts across repos: everything is centralized here.

## Scope
- Reusable GitHub Actions workflows (`workflow_call`) and shared actions
- Governance policies (labels, PR metadata, gates)
- Release/verify tooling
- Cross-repo docs (governance, migration, runbooks)

## Non-goals
- Runtime / product features (these belong to the core repos)
