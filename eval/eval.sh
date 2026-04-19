#!/usr/bin/env bash
# Run the amm-match harness for N_SIMS simulations and print a parseable
# score block. Agents read the edge via: grep "^edge:" run.log
#
# A strategy that fails to compile or crashes mid-run is NOT the same as
# a strategy that scored zero. On such failures this script exits non-zero
# without emitting a score block.
set -euo pipefail

cd "$(dirname "$0")/.."

VENV_DIR=".venv"
if [ -d "$VENV_DIR" ]; then
  # shellcheck disable=SC1091
  source "$VENV_DIR/bin/activate"
fi

N_SIMS=1000
STRATEGY=strategy.sol

OUTPUT=$(amm-match run "$STRATEGY" --simulations "$N_SIMS" 2>&1)
echo "$OUTPUT"

EDGE=$(printf '%s\n' "$OUTPUT" | awk '/Edge:/ { last=$NF } END { if (last != "") print last }')

if [ -z "${EDGE}" ]; then
  echo "ERROR: amm-match did not print an Edge score." >&2
  exit 1
fi

echo
echo "---"
printf "edge:            %s\n" "$EDGE"
printf "correct:         %s\n" "$N_SIMS"
printf "total:           %s\n" "$N_SIMS"
