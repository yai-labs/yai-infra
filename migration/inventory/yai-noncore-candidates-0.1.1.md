# YAI Non-Core Candidates (Wave 0.1.1)

Repository analyzed: `yai`

| Path | Class | Files | Notes |
|---|---:|---:|---|
| `tools/python/yai_tools` | infra-governance-tooling | 53 | candidate for move to yai-infra |
| `tools/bin` | wrapper-and-governance-entrypoints | 27 | candidate for move to yai-infra |
| `tools/ops` | cross-repo-ops-suite | 43 | candidate for move to yai-infra |
| `tools/schemas/docs` | docs-schema-governance | 8 | candidate for move to yai-infra |
| `docs/dev-guide` | cross-repo-governance-docs | 22 | candidate for move to yai-infra |
| `docs/templates` | cross-repo-doc-templates | 5 | candidate for move to yai-infra |
| `docs/_policy` | docs-policy | 2 | candidate for move to yai-infra |
| `docs/proof` | proof-process-docs | 3 | candidate for move to yai-infra |

## Keep In YAI (Runtime/Core)

- `boot/`, `root/`, `kernel/`, `engine/`, `mind/`, `runtime/`, `law/`
- runtime-facing docs: `docs/user-guide`, `docs/getting-started`, `docs/architecture` (where runtime-specific)
- build artifacts and release bundle outputs strictly tied to runtime binaries

## Migration Principle

- Move governance/process/cross-repo assets to `yai-infra`.
- Keep only thin compatibility wrappers in `yai/tools/bin` where needed.
- Avoid duplicate canonical docs/templates across repos.
