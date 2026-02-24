# Toolkit Contract

This document defines the canonical way to consume `yai-infra` tooling.

## Canonical entrypoint

Use `tools/bin/*` as the only supported front door.

Do not call internal Python modules or nested shell scripts directly from consumer CI.

## Install/use patterns

### Local checkout mode

```bash
cd yai-infra
export PATH="$PWD/tools/bin:$PATH"
yai-version
```

### Consumer wrapper mode

Consumer repos should keep thin wrappers under their local `tools/bin/` that delegate to `yai-infra/tools/bin/*`.

## Version/debug contract

- `tools/VERSION` is the canonical toolkit semantic version.
- `tools/bin/yai-version` is the mandatory debug command for CI/local troubleshooting.
- CI logs should print `yai-version` at start of governance/tooling jobs.

## Stability rules

- Existing command names in `tools/bin/` are stable public entrypoints.
- Breaking CLI flags or output shape requires a version bump in `tools/VERSION`.
- New commands must be documented in `tools/bin/README.md` and this contract.

## Troubleshooting

- If a command fails in consumer repo, verify `YAI_INFRA_ROOT` resolution and run:
  - `tools/bin/yai-version`
  - `tools/bin/<command> --help`


## Naming migration (specs -> law)

- Canonical command: `tools/bin/yai-law-sync`
- Compatibility alias: `tools/bin/yai-specs-sync` (deprecated)
