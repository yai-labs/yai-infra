#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="${ROOT}/governance/templates/github/.github"
DST="${ROOT}/.github"
MODE="apply"

if [[ "${1:-}" == "--check" ]]; then
  MODE="check"
fi

if [[ ! -d "${SRC}" ]]; then
  echo "canonical template source not found: ${SRC}" >&2
  exit 1
fi

mkdir -p "${DST}/ISSUE_TEMPLATE" "${DST}/PULL_REQUEST_TEMPLATE"

sync_file() {
  local rel="$1"
  local src="${SRC}/${rel}"
  local dst="${DST}/${rel}"
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
  local src_dir="${SRC}/${rel}"
  local dst_dir="${DST}/${rel}"
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

sync_file "PULL_REQUEST_TEMPLATE.md"
sync_dir "ISSUE_TEMPLATE"
sync_dir "PULL_REQUEST_TEMPLATE"

if [[ "${MODE}" == "apply" ]]; then
  echo "templates synced from canonical source into .github"
else
  echo "template mirror is aligned"
fi
