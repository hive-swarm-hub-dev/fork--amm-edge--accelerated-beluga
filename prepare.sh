#!/usr/bin/env bash
# One-time setup: create a local virtualenv, build the Rust simulation engine,
# install the amm-competition package, pre-install solc. Safe to re-run.
set -euo pipefail

cd "$(dirname "$0")"

VENV_DIR=".venv"

if [ ! -d "$VENV_DIR" ]; then
  echo "Creating virtualenv at $VENV_DIR..."
  python3 -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

echo "Installing build dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

echo "Building Rust simulation engine (first run takes several minutes)..."
# maturin refuses to run if both VIRTUAL_ENV and CONDA_PREFIX are set.
if [ -n "${CONDA_PREFIX:-}" ]; then
  ( cd amm_sim_rs && env -u CONDA_PREFIX -u CONDA_DEFAULT_ENV maturin develop --release )
else
  ( cd amm_sim_rs && maturin develop --release )
fi

echo "Installing amm-competition Python package..."
pip install -e .

echo "Pre-installing solc 0.8.24..."
python -c "import solcx; solcx.install_solc('0.8.24')" 2>/dev/null || true

echo "Prepare complete. Run: bash eval/eval.sh"
