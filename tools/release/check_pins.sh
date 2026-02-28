#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# YAI Infra — Check Pins (core <-> cli <-> law, optional sdk)
# ============================================================
#
# Inputs:
#   - YAI_CORE_ROOT      : path to yai core repo (optional)
#   - YAI_SPECS_ROOT     : path to deps/yai-law (optional)
#   - YAI_LAW_REPO       : remote repo for yai-law (optional)
#   - YAI_CLI_REPO       : remote repo for yai-cli (optional)
#   - YAI_SDK_REPO       : remote repo for yai-sdk (optional)
#   - STRICT_SPECS_HEAD  : 1|0 (default 1) require law pin == yai-law/main HEAD
#
# Core requirement:
#   core repo must contain:
#     - deps/yai-cli.ref (cli_sha=...)
#     - deps/yai-law (gitlink / submodule)
#   Optional chain:
#     - deps/yai-sdk.ref (sdk_sha=...) => sdk becomes authoritative law pin source
#

YAI_LAW_REPO="${YAI_LAW_REPO:-https://github.com/yai-labs/yai-law.git}"
YAI_CLI_REPO="${YAI_CLI_REPO:-https://github.com/yai-labs/yai-cli.git}"
YAI_SDK_REPO="${YAI_SDK_REPO:-https://github.com/yai-labs/yai-sdk.git}"
STRICT_SPECS_HEAD="${STRICT_SPECS_HEAD:-1}"

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
LAW_ROOT="${YAI_SPECS_ROOT:-$ROOT/deps/yai-law}"

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
  local yai_cli_ref_law_pin="${7:-unknown}"
  local yai_sdk_ref_sha="${8:-unknown}"
  local yai_sdk_law_pin="${9:-unknown}"

  echo
  echo "[RESULT] FAIL"
  echo "[REASON] $msg"
  echo "         core_root=$ROOT"
  echo "         law_root=$LAW_ROOT"

  echo
  echo "[MACHINE]"
  echo "result=FAIL"
  echo "reason=$msg"
  echo "exit_code=$code"
  echo "core_root=$ROOT"
  echo "law_root=$LAW_ROOT"
  echo "yai_pin=$yai_pin"
  echo "yai_cli_pin=$yai_cli_pin"
  echo "yai_cli_ref_sha=$yai_cli_ref_sha"
  echo "yai_cli_ref_specs_pin=$yai_cli_ref_law_pin"
  echo "yai_sdk_ref_sha=$yai_sdk_ref_sha"
  echo "yai_sdk_law_pin=$yai_sdk_law_pin"
  if [[ -n "$expected_sha" ]]; then
    echo "expected_specs_sha=$expected_sha"
  fi
  exit "$code"
}

require_dir() {
  local path="$1"
  local what="$2"
  [[ -d "$path" ]] || fail 3 "missing $what: $path"
}

read_ref_sha() {
  local ref_file="$1"
  local key="$2"
  [[ -f "$ref_file" ]] || return 1
  local sha
  sha="$(sed -n "s/^${key}=//p" "$ref_file" | tr -d '\r' | head -n1)"
  echo "$sha" | grep -Eq '^[0-9a-f]{40}$' || return 1
  printf "%s" "$sha"
}

extract_gitlink() {
  local repo_dir="$1"
  local ref="${2:-HEAD}"
  local path_rel="$3"

  local entry
  entry="$(git -C "$repo_dir" ls-tree -d "$ref" "$path_rel" | awk '{print $3}' | head -n1 || true)"
  if ! echo "$entry" | grep -Eq '^[0-9a-f]{40}$'; then
    echo ""
    return 0
  fi
  printf "%s" "$entry"
}

# ------------------------
# Preflight
# ------------------------
require_dir "$ROOT" "core root"
require_dir "$ROOT/deps" "deps directory"

if [[ ! -d "$LAW_ROOT/.git" ]] && [[ ! -f "$LAW_ROOT/.git" ]]; then
  fail 3 "deps/yai-law is not a git repo; cannot verify pin"
fi

YAI_LAW_PIN="$(git -C "$LAW_ROOT" rev-parse HEAD 2>/dev/null || true)"
echo "$YAI_LAW_PIN" | grep -Eq '^[0-9a-f]{40}$' || fail 3 "invalid yai-law pin from deps/yai-law"

CLI_REF_FILE="$ROOT/deps/yai-cli.ref"
CLI_SHA="$(read_ref_sha "$CLI_REF_FILE" "cli_sha" || true)"
[[ -n "$CLI_SHA" ]] || fail 3 "missing/invalid deps/yai-cli.ref (cli_sha=...)"

SDK_REF_FILE="$ROOT/deps/yai-sdk.ref"
SDK_SHA="$(read_ref_sha "$SDK_REF_FILE" "sdk_sha" || true)"

# ------------------------
# Resolve yai-cli main + its law gitlink
# ------------------------
YAI_CLI_MAIN_SHA="$(git ls-remote "$YAI_CLI_REPO" refs/heads/main | awk '{print $1}' | head -n1 || true)"
echo "$YAI_CLI_MAIN_SHA" | grep -Eq '^[0-9a-f]{40}$' || fail 3 "cannot resolve yai-cli main HEAD from $YAI_CLI_REPO"

CLI_MAIN_TMP="$TMP_DIR/yai-cli-main"
git clone --no-checkout "$YAI_CLI_REPO" "$CLI_MAIN_TMP" >/dev/null 2>&1
git -C "$CLI_MAIN_TMP" fetch --depth 1 origin "$YAI_CLI_MAIN_SHA" >/dev/null 2>&1 || fail 3 "cannot fetch yai-cli main commit $YAI_CLI_MAIN_SHA from $YAI_CLI_REPO"
git -C "$CLI_MAIN_TMP" checkout -q "$YAI_CLI_MAIN_SHA" >/dev/null 2>&1 || fail 3 "cannot checkout yai-cli main commit $YAI_CLI_MAIN_SHA"

YAI_CLI_LAW_PIN="$(extract_gitlink "$CLI_MAIN_TMP" HEAD "deps/yai-law")"
echo "$YAI_CLI_LAW_PIN" | grep -Eq '^[0-9a-f]{40}$' || fail 3 "could not resolve yai-cli law pin from gitlink deps/yai-law"

# ------------------------
# Resolve yai-cli.ref commit + its law gitlink
# ------------------------
CLI_REF_TMP="$TMP_DIR/yai-cli-ref"
git clone --no-checkout "$YAI_CLI_REPO" "$CLI_REF_TMP" >/dev/null 2>&1
git -C "$CLI_REF_TMP" fetch --depth 1 origin "$CLI_SHA" >/dev/null 2>&1 || fail 3 "cannot fetch yai-cli ref commit $CLI_SHA from $YAI_CLI_REPO"
git -C "$CLI_REF_TMP" checkout -q "$CLI_SHA" >/dev/null 2>&1 || fail 3 "cannot checkout yai-cli ref commit $CLI_SHA"

CLI_REF_LAW_PIN="$(extract_gitlink "$CLI_REF_TMP" HEAD "deps/yai-law")"
echo "$CLI_REF_LAW_PIN" | grep -Eq '^[0-9a-f]{40}$' || fail 3 "could not resolve law pin for yai-cli.ref commit $CLI_SHA"

# ------------------------
# Optional: SDK chain (authoritative expected law pin)
# ------------------------
SDK_LAW_PIN=""
if [[ -n "$SDK_SHA" ]]; then
  SDK_TMP="$TMP_DIR/yai-sdk-ref"
  git clone --no-checkout "$YAI_SDK_REPO" "$SDK_TMP" >/dev/null 2>&1 || fail 3 "cannot clone yai-sdk from $YAI_SDK_REPO"
  git -C "$SDK_TMP" fetch --depth 1 origin "$SDK_SHA" >/dev/null 2>&1 || fail 3 "cannot fetch yai-sdk ref commit $SDK_SHA from $YAI_SDK_REPO"
  git -C "$SDK_TMP" checkout -q "$SDK_SHA" >/dev/null 2>&1 || fail 3 "cannot checkout yai-sdk ref commit $SDK_SHA"
  SDK_LAW_PIN="$(extract_gitlink "$SDK_TMP" HEAD "deps/yai-law")"
  echo "$SDK_LAW_PIN" | grep -Eq '^[0-9a-f]{40}$' || fail 3 "could not resolve yai-sdk law pin from gitlink deps/yai-law"
fi

# ------------------------
# Resolve yai-law main HEAD + reachability
# ------------------------
LAW_HEAD="$(git ls-remote "$YAI_LAW_REPO" refs/heads/main | awk '{print $1}' | head -n1 || true)"
echo "$LAW_HEAD" | grep -Eq '^[0-9a-f]{40}$' || fail 3 "cannot resolve yai-law main HEAD from $YAI_LAW_REPO"

CHECK_TMP="$TMP_DIR/law-check"
git init -q "$CHECK_TMP"
git -C "$CHECK_TMP" remote add origin "$YAI_LAW_REPO"
git -C "$CHECK_TMP" fetch --depth 1 origin "$YAI_LAW_PIN" >/dev/null 2>&1 || fail 3 "yai-law pin $YAI_LAW_PIN is not reachable in $YAI_LAW_REPO" "$LAW_HEAD" "$YAI_LAW_PIN" "$YAI_CLI_LAW_PIN" "$CLI_SHA" "$CLI_REF_LAW_PIN" "$SDK_SHA" "$SDK_LAW_PIN"

# ------------------------
# Decide expected law pin
# ------------------------
EXPECTED_LAW_SHA="$YAI_LAW_PIN"
EXPECTED_MODE="core"

if [[ -n "$SDK_SHA" ]]; then
  EXPECTED_LAW_SHA="$SDK_LAW_PIN"
  EXPECTED_MODE="sdk"
fi

if [[ "$STRICT_SPECS_HEAD" = "1" ]]; then
  EXPECTED_LAW_SHA="$LAW_HEAD"
  EXPECTED_MODE="law-head"
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
if [[ -n "$SDK_SHA" ]]; then
  echo "  yai_sdk_ref_sha    : $(short_sha "$SDK_SHA")"
  echo "  yai_sdk_law_pin    : $(short_sha "$SDK_LAW_PIN")"
fi
echo "  strict_specs_head  : $STRICT_SPECS_HEAD"
echo "  expected_mode      : $EXPECTED_MODE"
echo "  expected_law_sha   : $(short_sha "$EXPECTED_LAW_SHA")"

# ------------------------
# Enforce alignment
# ------------------------
[[ "$YAI_LAW_PIN" == "$EXPECTED_LAW_SHA" ]] || fail 2 "core deps/yai-law pin mismatch vs expected" "$EXPECTED_LAW_SHA" "$YAI_LAW_PIN" "$YAI_CLI_LAW_PIN" "$CLI_SHA" "$CLI_REF_LAW_PIN" "$SDK_SHA" "$SDK_LAW_PIN"
[[ "$YAI_CLI_LAW_PIN" == "$EXPECTED_LAW_SHA" ]] || fail 2 "yai-cli main deps/yai-law pin mismatch vs expected" "$EXPECTED_LAW_SHA" "$YAI_LAW_PIN" "$YAI_CLI_LAW_PIN" "$CLI_SHA" "$CLI_REF_LAW_PIN" "$SDK_SHA" "$SDK_LAW_PIN"
[[ "$CLI_REF_LAW_PIN" == "$EXPECTED_LAW_SHA" ]] || fail 5 "yai-cli.ref commit is not aligned to expected yai-law pin" "$EXPECTED_LAW_SHA" "$YAI_LAW_PIN" "$YAI_CLI_LAW_PIN" "$CLI_SHA" "$CLI_REF_LAW_PIN" "$SDK_SHA" "$SDK_LAW_PIN"

# Required paths inside law tree (sanity)
REQUIRED_LAW_PATHS=(
  "$LAW_ROOT/VERSION"
  "$LAW_ROOT/SPEC_MAP.md"
  "$LAW_ROOT/contracts/protocol/include/protocol.h"
  "$LAW_ROOT/contracts/vault/include/yai_vault_abi.h"
  "$LAW_ROOT/formal/tla/YAI_KERNEL.tla"
  "$LAW_ROOT/tools/release/bump_version.sh"
)
for path in "${REQUIRED_LAW_PATHS[@]}"; do
  [[ -f "$path" ]] || fail 3 "missing required law path: ${path#$ROOT/}" "$EXPECTED_LAW_SHA" "$YAI_LAW_PIN" "$YAI_CLI_LAW_PIN" "$CLI_SHA" "$CLI_REF_LAW_PIN" "$SDK_SHA" "$SDK_LAW_PIN"
done

echo
echo "[RESULT] PASS"
echo "[REASON] aligned law pins (core/cli/cli.ref) with optional sdk chain"
echo
echo "[MACHINE]"
echo "result=PASS"
echo "reason=aligned law pins (core/cli/cli.ref) with optional sdk chain"
echo "exit_code=0"
echo "core_root=$ROOT"
echo "law_root=$LAW_ROOT"
echo "yai_pin=$YAI_LAW_PIN"
echo "yai_cli_pin=$YAI_CLI_LAW_PIN"
echo "yai_cli_ref_sha=$CLI_SHA"
echo "yai_cli_ref_specs_pin=$CLI_REF_LAW_PIN"
echo "yai_sdk_ref_sha=${SDK_SHA:-}"
echo "yai_sdk_law_pin=${SDK_LAW_PIN:-}"
echo "expected_specs_sha=$EXPECTED_LAW_SHA"
echo "PASS: alignment OK."
