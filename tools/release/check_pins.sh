#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# YAI Infra — Check Pins (core <-> cli <-> law triangle)
# ============================================================
#
# Inputs:
#   - YAI_CORE_ROOT   : path to yai core repo (optional)
#   - YAI_SPECS_ROOT  : path to deps/yai-law (optional)
#   - YAI_LAW_REPO    : remote repo for yai-law (optional)
#   - YAI_CLI_REPO    : remote repo for yai-cli (optional)
#   - STRICT_SPECS_HEAD : 1|0 (default 1)  -> require law pin == law/main HEAD
#   - STRICT_BUNDLE_ENTRYPOINT : 1|0 (optional) -> validate bundle scripts present
#
# Core requirement:
#   core repo must contain:
#     - deps/yai-cli.ref (cli_sha=...)
#     - deps/yai-law (gitlink / submodule)
#

YAI_LAW_REPO="${YAI_LAW_REPO:-https://github.com/yai-labs/yai-law.git}"
YAI_CLI_REPO="${YAI_CLI_REPO:-https://github.com/yai-labs/yai-cli.git}"
STRICT_SPECS_HEAD="${STRICT_SPECS_HEAD:-1}"

# ------------------------
# Workspace resolution
# ------------------------
resolve_root() {
  if [[ -n "${YAI_CORE_ROOT:-}" ]]; then
    printf "%s" "$YAI_CORE_ROOT"
    return 0
  fi
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    git rev-parse --show-toplevel
    return 0
  fi
  pwd
}

ROOT="$(resolve_root)"
SPECS_ROOT="${YAI_SPECS_ROOT:-$ROOT/deps/yai-law}"

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

short_sha() {
  local sha="${1:-}"
  if echo "$sha" | grep -Eq '^[0-9a-f]{40}$'; then
    printf "%s" "${sha:0:12}"
  else
    printf "%s" "$sha"
  fi
}

fail() {
  local code="$1"
  local msg="$2"
  local expected_sha="${3:-}"
  local yai_pin="${4:-unknown}"
  local yai_cli_pin="${5:-unknown}"
  local yai_cli_ref_sha="${6:-unknown}"
  local yai_cli_ref_specs_pin="${7:-unknown}"

  echo
  echo "[RESULT] FAIL"
  echo "[REASON] $msg"
  echo "         core_root=$ROOT"
  echo "         law_root=$SPECS_ROOT"

  if [[ -n "$expected_sha" ]] && { [[ "$code" -eq 2 ]] || [[ "$code" -eq 3 ]] || [[ "$code" -eq 4 ]]; }; then
    print_fix_plan "$expected_sha" "$yai_pin" "$yai_cli_pin"
  fi
  if [[ -n "$expected_sha" ]] && [[ "$code" -eq 5 ]]; then
    print_triangle_fix_plan "$expected_sha" "$yai_cli_ref_sha" "$yai_cli_ref_specs_pin"
  fi

  echo
  echo "[MACHINE]"
  echo "result=FAIL"
  echo "reason=$msg"
  echo "exit_code=$code"
  echo "core_root=$ROOT"
  echo "law_root=$SPECS_ROOT"
  echo "yai_pin=$yai_pin"
  echo "yai_cli_pin=$yai_cli_pin"
  echo "yai_cli_ref_sha=$yai_cli_ref_sha"
  echo "yai_cli_ref_specs_pin=$yai_cli_ref_specs_pin"
  if [[ -n "$expected_sha" ]]; then
    echo "expected_law_sha=$expected_sha"
  fi
  exit "$code"
}

require_dir() {
  local path="$1"
  local what="$2"
  [[ -d "$path" ]] || fail 3 "missing $what: $path"
}

read_cli_sha_ref() {
  local ref_file="$ROOT/deps/yai-cli.ref"
  if [[ ! -f "$ref_file" ]]; then
    fail 3 "missing deps/yai-cli.ref (expected: $ref_file)"
  fi
  local cli_sha
  cli_sha="$(sed -n 's/^cli_sha=//p' "$ref_file" | tr -d '\r' | head -n1)"
  if ! echo "$cli_sha" | grep -Eq '^[0-9a-f]{40}$'; then
    fail 3 "invalid deps/yai-cli.ref (missing/invalid cli_sha=...)"
  fi
  printf "%s" "$cli_sha"
}

extract_law_gitlink() {
  # Extract gitlink SHA for deps/yai-law in a given repo at ref
  local repo_dir="$1"
  local ref="${2:-HEAD}"

  # Ensure the path exists as a tree entry
  local entry
  entry="$(git -C "$repo_dir" ls-tree -d "$ref" deps/yai-law | awk '{print $3}' | head -n1 || true)"
  if ! echo "$entry" | grep -Eq '^[0-9a-f]{40}$'; then
    echo ""
    return 0
  fi
  printf "%s" "$entry"
}

print_fix_plan() {
  local expected_sha="$1"
  local yai_pin="$2"
  local yai_cli_pin="$3"
  local short="${expected_sha:0:7}"

  cat <<EOF
[SUMMARY]
  expected_law_sha    : ${expected_sha}
  yai_law_pin         : ${yai_pin}
  yai_cli_law_pin     : ${yai_cli_pin}

Fix (required before release):

  export YAI_WORKSPACE="<path-to-your-yai-workspace>"

  yai-cli (bump deps/yai-law to ${expected_sha})
    cd "\$YAI_WORKSPACE/yai-cli"
    git checkout main && git pull --rebase
    git checkout -b chore/bump-law-${short}
    git -C deps/yai-law fetch origin
    git -C deps/yai-law checkout ${expected_sha}
    git add deps/yai-law
    git commit -m "chore(law): bump yai-law pin to ${short} in yai-cli"
    git push -u origin chore/bump-law-${short}

  yai (bump deps/yai-law to ${expected_sha})
    cd "\$YAI_WORKSPACE/yai"
    git checkout main && git pull --rebase
    git checkout -b chore/bump-law-${short}
    git -C deps/yai-law fetch origin
    git -C deps/yai-law checkout ${expected_sha}
    git add deps/yai-law
    git commit -m "chore(law): bump yai-law pin to ${short} in yai"
    git push -u origin chore/bump-law-${short}

  close bump branches (after PR merge to main)
    cd "\$YAI_WORKSPACE/yai-cli"
    git checkout main && git pull --rebase
    git branch -d chore/bump-law-${short} || git branch -D chore/bump-law-${short}
    git push origin --delete chore/bump-law-${short} || true

    cd "\$YAI_WORKSPACE/yai"
    git checkout main && git pull --rebase
    git branch -d chore/bump-law-${short} || git branch -D chore/bump-law-${short}
    git push origin --delete chore/bump-law-${short} || true
EOF
}

print_triangle_fix_plan() {
  local expected_sha="$1"
  local cli_sha="$2"
  local cli_ref_law_pin="$3"
  local shortlaw="${expected_sha:0:7}"

  cat <<EOF
[SUMMARY]
  expected_law_sha    : ${expected_sha}
  yai_cli_ref_sha     : ${cli_sha}
  yai_cli_ref_law_pin : ${cli_ref_law_pin}

Fix (required before release):

  export YAI_WORKSPACE="<path-to-your-yai-workspace>"

  yai-cli (prepare an aligned commit pinned to ${expected_sha})
    cd "\$YAI_WORKSPACE/yai-cli"
    git checkout main && git pull --rebase
    # ensure deps/yai-law gitlink matches expected
    git ls-tree -d HEAD deps/yai-law
    # if mismatch: bump yai-law pin in yai-cli, merge it, then:
    NEW_CLI_SHA=\$(git rev-parse HEAD)

  yai (update deps/yai-cli.ref to aligned CLI commit)
    cd "\$YAI_WORKSPACE/yai"
    git checkout main && git pull --rebase
    git checkout -b chore/bump-cli-ref-${shortlaw}
    printf "cli_sha=%s\n" "\$NEW_CLI_SHA" > deps/yai-cli.ref
    git add deps/yai-cli.ref
    git commit -m "chore(release): pin yai-cli to \${NEW_CLI_SHA:0:7}"
    git push -u origin chore/bump-cli-ref-${shortlaw}
EOF
}

# ------------------------
# Preflight: core + law repo existence
# ------------------------
require_dir "$ROOT" "core root"
require_dir "$ROOT/deps" "deps directory"

# Accept both .git directory and .git file (submodule uses .git file)
if [[ ! -d "$SPECS_ROOT/.git" ]] && [[ ! -f "$SPECS_ROOT/.git" ]]; then
  fail 3 "deps/yai-law is not a git repo; cannot verify pin"
fi

YAI_LAW_PIN="$(git -C "$SPECS_ROOT" rev-parse HEAD 2>/dev/null || true)"
if ! echo "$YAI_LAW_PIN" | grep -Eq '^[0-9a-f]{40}$'; then
  fail 3 "invalid yai-law pin from deps/yai-law"
fi

CLI_SHA="$(read_cli_sha_ref)"

# ------------------------
# Resolve yai-cli main + its law gitlink
# ------------------------
YAI_CLI_MAIN_SHA="$(git ls-remote "$YAI_CLI_REPO" refs/heads/main | awk '{print $1}' | head -n1 || true)"
if ! echo "$YAI_CLI_MAIN_SHA" | grep -Eq '^[0-9a-f]{40}$'; then
  fail 3 "cannot resolve yai-cli main HEAD from $YAI_CLI_REPO"
fi

CLI_MAIN_TMP="$TMP_DIR/yai-cli-main"
git clone --no-checkout "$YAI_CLI_REPO" "$CLI_MAIN_TMP" >/dev/null 2>&1
if ! git -C "$CLI_MAIN_TMP" fetch --depth 1 origin "$YAI_CLI_MAIN_SHA" >/dev/null 2>&1; then
  fail 3 "cannot fetch yai-cli main commit $YAI_CLI_MAIN_SHA from $YAI_CLI_REPO"
fi
if ! git -C "$CLI_MAIN_TMP" checkout -q "$YAI_CLI_MAIN_SHA" >/dev/null 2>&1; then
  fail 3 "cannot checkout yai-cli main commit $YAI_CLI_MAIN_SHA"
fi

YAI_CLI_LAW_PIN="$(extract_law_gitlink "$CLI_MAIN_TMP" HEAD)"
if ! echo "$YAI_CLI_LAW_PIN" | grep -Eq '^[0-9a-f]{40}$'; then
  fail 3 "could not resolve yai-cli law pin from gitlink deps/yai-law"
fi

# ------------------------
# Resolve yai-cli.ref commit + its law gitlink
# ------------------------
CLI_REF_TMP="$TMP_DIR/yai-cli-ref"
git clone --no-checkout "$YAI_CLI_REPO" "$CLI_REF_TMP" >/dev/null 2>&1
if ! git -C "$CLI_REF_TMP" fetch --depth 1 origin "$CLI_SHA" >/dev/null 2>&1; then
  fail 3 "cannot fetch yai-cli ref commit $CLI_SHA from $YAI_CLI_REPO"
fi
if ! git -C "$CLI_REF_TMP" checkout -q "$CLI_SHA" >/dev/null 2>&1; then
  fail 3 "cannot checkout yai-cli ref commit $CLI_SHA"
fi
CLI_REF_LAW_PIN="$(extract_law_gitlink "$CLI_REF_TMP" HEAD)"
if ! echo "$CLI_REF_LAW_PIN" | grep -Eq '^[0-9a-f]{40}$'; then
  fail 3 "could not resolve law pin for yai-cli.ref commit $CLI_SHA"
fi

# ------------------------
# Resolve yai-law main HEAD + reachability of current pin
# ------------------------
LAW_HEAD="$(git ls-remote "$YAI_LAW_REPO" refs/heads/main | awk '{print $1}' | head -n1 || true)"
if ! echo "$LAW_HEAD" | grep -Eq '^[0-9a-f]{40}$'; then
  fail 3 "cannot resolve yai-law main HEAD from $YAI_LAW_REPO"
fi

CHECK_TMP="$TMP_DIR/law-check"
git init -q "$CHECK_TMP"
git -C "$CHECK_TMP" remote add origin "$YAI_LAW_REPO"

if ! git -C "$CHECK_TMP" fetch --depth 1 origin "$YAI_LAW_PIN" >/dev/null 2>&1; then
  fail 3 "yai-law pin $YAI_LAW_PIN is not reachable in $YAI_LAW_REPO" "$LAW_HEAD" "$YAI_LAW_PIN" "$YAI_CLI_LAW_PIN"
fi
if ! git -C "$CHECK_TMP" cat-file -e "${YAI_LAW_PIN}^{commit}" >/dev/null 2>&1; then
  fail 3 "yai-law pin $YAI_LAW_PIN is not a valid commit in $YAI_LAW_REPO" "$LAW_HEAD" "$YAI_LAW_PIN" "$YAI_CLI_LAW_PIN"
fi

# ------------------------
# Report
# ------------------------
echo "[CHECK]"
echo "  yai_law_pin        : $(short_sha "$YAI_LAW_PIN")"
echo "  yai_cli_law_pin    : $(short_sha "$YAI_CLI_LAW_PIN")"
echo "  yai_cli_ref_sha    : $(short_sha "$CLI_SHA")"
echo "  yai_cli_ref_law    : $(short_sha "$CLI_REF_LAW_PIN")"
echo "  yai_cli_main_head  : $(short_sha "$YAI_CLI_MAIN_SHA")"
echo "  yai_law_main_head  : $(short_sha "$LAW_HEAD")"
echo "  strict_specs_head  : $STRICT_SPECS_HEAD"

# Pin mismatch between core and cli(main)
if [[ "$YAI_LAW_PIN" != "$YAI_CLI_LAW_PIN" ]]; then
  fail 2 "pin mismatch between yai and yai-cli (main)" "$LAW_HEAD" "$YAI_LAW_PIN" "$YAI_CLI_LAW_PIN"
fi

# Strict: core pin must equal yai-law/main head
if [[ "$STRICT_SPECS_HEAD" = "1" ]] && [[ "$YAI_LAW_PIN" != "$LAW_HEAD" ]]; then
  fail 4 "strict mode enabled and pin is not yai-law/main HEAD" "$LAW_HEAD" "$YAI_LAW_PIN" "$YAI_CLI_LAW_PIN" "$CLI_SHA" "$CLI_REF_LAW_PIN"
fi

EXPECTED_LAW_SHA="$YAI_LAW_PIN"
if [[ "$STRICT_SPECS_HEAD" = "1" ]]; then
  EXPECTED_LAW_SHA="$LAW_HEAD"
fi
echo "  expected_law_sha   : $(short_sha "$EXPECTED_LAW_SHA")"

# Triangle: yai-cli.ref commit must be aligned to expected law pin
if [[ "$CLI_REF_LAW_PIN" != "$EXPECTED_LAW_SHA" ]]; then
  fail 5 "yai-cli.ref commit is not aligned to expected yai-law pin" "$EXPECTED_LAW_SHA" "$YAI_LAW_PIN" "$YAI_CLI_LAW_PIN" "$CLI_SHA" "$CLI_REF_LAW_PIN"
fi

# Required paths inside law tree (sanity)
REQUIRED_LAW_PATHS=(
  "$SPECS_ROOT/VERSION"
  "$SPECS_ROOT/SPEC_MAP.md"
  "$SPECS_ROOT/contracts/protocol/include/protocol.h"
  "$SPECS_ROOT/contracts/vault/include/yai_vault_abi.h"
  "$SPECS_ROOT/formal/tla/YAI_KERNEL.tla"
  "$SPECS_ROOT/tools/release/bump_version.sh"
)
for path in "${REQUIRED_LAW_PATHS[@]}"; do
  [[ -f "$path" ]] || fail 3 "missing required law path: ${path#$ROOT/}"
done

# Optional: bundle entrypoint checks in core repo
if [[ "${STRICT_BUNDLE_ENTRYPOINT:-0}" = "1" ]]; then
  [[ -x "$ROOT/tools/bundle/build_bundle.sh" ]] || fail 3 "missing executable tools/bundle/build_bundle.sh"
  [[ -x "$ROOT/tools/bundle/manifest.sh" ]] || fail 3 "missing executable tools/bundle/manifest.sh"
  grep -qE '^bundle:' "$ROOT/Makefile" || fail 3 "Makefile missing bundle target"
  echo "[CHECK] bundle entrypoint scripts present"
fi

echo
echo "[RESULT] PASS"
echo "[REASON] aligned yai-law pins and yai-cli.ref triangle"
echo
echo "[MACHINE]"
echo "result=PASS"
echo "reason=aligned yai-law pins and yai-cli.ref triangle"
echo "exit_code=0"
echo "core_root=$ROOT"
echo "law_root=$SPECS_ROOT"
echo "yai_pin=$YAI_LAW_PIN"
echo "yai_cli_pin=$YAI_CLI_LAW_PIN"
echo "yai_cli_ref_sha=$CLI_SHA"
echo "yai_cli_ref_specs_pin=$CLI_REF_LAW_PIN"
echo "expected_specs_sha=$EXPECTED_LAW_SHA"
echo "PASS: yai, yai-cli, and yai-cli.ref are aligned and valid."