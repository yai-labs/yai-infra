#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC_ROOT="${ROOT}/governance/templates/github/.github"
MODE=""
TARGET=""

usage() {
  cat <<USAGE
Usage:
  tools/sh/sync_github_templates.sh sync --target <path-to-repo>
  tools/sh/sync_github_templates.sh check --target <path-to-repo>

Scope mirrored:
- .github/ISSUE_TEMPLATE/**
- .github/PULL_REQUEST_TEMPLATE/**
- .github/PULL_REQUEST_TEMPLATE.md
- .github/labeler.yml
- .github/.managed-by-yai-infra
USAGE
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 2
fi

MODE="$1"
shift

case "${MODE}" in
  sync|check) ;;
  -h|--help|help)
    usage
    exit 0
    ;;
  *)
    echo "invalid mode: ${MODE}" >&2
    usage >&2
    exit 2
    ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      if [[ $# -lt 2 ]]; then
        echo "missing value for --target" >&2
        exit 2
      fi
      TARGET="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${TARGET}" ]]; then
  echo "--target is required" >&2
  usage >&2
  exit 2
fi

if [[ ! -d "${SRC_ROOT}" ]]; then
  echo "canonical template source not found: ${SRC_ROOT}" >&2
  exit 1
fi

if [[ ! -d "${TARGET}" ]]; then
  echo "target repository path not found: ${TARGET}" >&2
  exit 1
fi

DST_ROOT="${TARGET%/}/.github"
mkdir -p "${DST_ROOT}" "${DST_ROOT}/ISSUE_TEMPLATE" "${DST_ROOT}/PULL_REQUEST_TEMPLATE"

sync_file() {
  local rel="$1"
  local src="${SRC_ROOT}/${rel}"
  local dst="${DST_ROOT}/${rel}"

  if [[ ! -f "${src}" ]]; then
    echo "missing source file: ${src}" >&2
    exit 1
  fi

  if [[ "${MODE}" == "check" ]]; then
    if [[ ! -f "${dst}" ]]; then
      echo "missing mirror file: ${dst}" >&2
      exit 1
    fi
    if ! diff -u "${src}" "${dst}" >/tmp/yai-template-diff.txt; then
      echo "template mirror drift detected for ${rel}" >&2
      cat /tmp/yai-template-diff.txt >&2
      exit 1
    fi
  else
    cp -f "${src}" "${dst}"
  fi
}

sync_dir() {
  local rel="$1"
  local src_dir="${SRC_ROOT}/${rel}"
  local dst_dir="${DST_ROOT}/${rel}"

  if [[ ! -d "${src_dir}" ]]; then
    echo "missing source dir: ${src_dir}" >&2
    exit 1
  fi

  mkdir -p "${dst_dir}"

  while IFS= read -r -d '' src_file; do
    local file_rel="${src_file#${src_dir}/}"
    sync_file "${rel}/${file_rel}"
  done < <(find "${src_dir}" -type f -print0 | sort -z)

  if [[ "${MODE}" == "check" ]]; then
    while IFS= read -r -d '' dst_file; do
      local file_rel="${dst_file#${dst_dir}/}"
      if [[ ! -f "${src_dir}/${file_rel}" ]]; then
        echo "extra mirror file not present in canonical source: ${rel}/${file_rel}" >&2
        exit 1
      fi
    done < <(find "${dst_dir}" -type f -print0 | sort -z)
  fi
}

sync_file ".managed-by-yai-infra"
sync_file "labeler.yml"
sync_file "PULL_REQUEST_TEMPLATE.md"
sync_dir "ISSUE_TEMPLATE"
sync_dir "PULL_REQUEST_TEMPLATE"

if [[ "${MODE}" == "sync" ]]; then
  echo "templates synced from canonical source into ${DST_ROOT}"
else
  echo "template mirror is aligned (${DST_ROOT})"
fi
