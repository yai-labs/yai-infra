#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC_ROOT="${ROOT}/governance/templates/github/.github"
DST_ROOT="${ROOT}/.github"

usage() {
  cat <<USAGE
Usage:
  tools/sh/sync_github_templates.sh sync   # write mirror from canonical source
  tools/sh/sync_github_templates.sh check  # fail if drift is detected
USAGE
}

MODE="${1:-sync}"
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

if [[ ! -d "${SRC_ROOT}" ]]; then
  echo "canonical template source not found: ${SRC_ROOT}" >&2
  exit 1
fi

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
    if ! diff -u "${src}" "${dst}" >/tmp/yai-infra-template-diff.txt; then
      echo "template mirror drift detected for ${rel}" >&2
      cat /tmp/yai-infra-template-diff.txt >&2
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
sync_file "PULL_REQUEST_TEMPLATE.md"
sync_dir "ISSUE_TEMPLATE"
sync_dir "PULL_REQUEST_TEMPLATE"

if [[ "${MODE}" == "sync" ]]; then
  echo "templates synced from canonical source into .github"
else
  echo "template mirror is aligned"
fi
