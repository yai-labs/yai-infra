# Schema Residency Policy

- Canonical docs schemas live in `yai-infra/tools/schemas/docs/`.
- Consumer repos can keep mirrored copies only when local tools require filesystem-local schemas.
- Schema changes are authored in `yai-infra` and then synchronized into consumers.
