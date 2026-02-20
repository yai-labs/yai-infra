# Rollback Plan

## Trigger Conditions
- Widespread CI breakage after cutover
- Missing critical workflow functionality

## Rollback Steps
1. In each consumer repo, revert workflow reference from `@v0.1.0` (or RC) to last known-good local workflow commit.
2. Restore removed local scripts/docs from git history where needed.
3. Open incident issue in `yai-infra` with impact summary and recovery ETA.

## Validation
- CI green on all affected repos.
- Developer workflows unblocked.
