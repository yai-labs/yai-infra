#!/usr/bin/env bash
set -euo pipefail

INFRA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CORE_ROOT="${YAI_CORE_ROOT:-$INFRA_ROOT}"
SPECS_CONTRACTS="$CORE_ROOT/deps/yai-law/contracts"
FORMAL="$CORE_ROOT/deps/yai-law/formal"
KERNEL="$CORE_ROOT/kernel"

TLA_JAR="${TLA_JAR:-$HOME/Developer/tools/tla/tla2tools.jar}"

echo "=== INFRA ROOT: $INFRA_ROOT"
echo "=== CORE ROOT:  $CORE_ROOT"
echo "=== CONTRACTS: $SPECS_CONTRACTS"
echo "=== KERNEL:    $KERNEL"
echo "=== FORMAL:    $FORMAL"
echo "=== TLA_JAR:   $TLA_JAR"

if [[ ! -f "$TLA_JAR" ]]; then
  echo "Missing TLA_JAR at $TLA_JAR. Set TLA_JAR or install tla2tools.jar."
  exit 1
fi

echo "=== CHECK GENERATED"
YAI_CORE_ROOT="$CORE_ROOT" bash "$INFRA_ROOT/tools/dev/check-generated.sh"

echo "=== KERNEL BUILD"
cd "$KERNEL"
make clean
make

echo "=== TLC QUICK"
cd "$FORMAL"
java -XX:+UseParallelGC -jar "$TLA_JAR" -modelcheck tla/YAI_KERNEL.tla -config configs/YAI_KERNEL.quick.cfg

echo "=== TLC DEEP"
java -XX:+UseParallelGC -jar "$TLA_JAR" -modelcheck tla/YAI_KERNEL.tla -config configs/YAI_KERNEL.deep.cfg

echo "OK: Law<->Kernel verification passed."
