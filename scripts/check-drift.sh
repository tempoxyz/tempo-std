#!/usr/bin/env bash
# check-drift.sh — wrapper around check-drift.py.
#
# Compares the tempo-std Solidity interface ABIs against the canonical Rust
# precompile interfaces in the tempo node repository. See check-drift.py for
# details. Requires a checkout of tempoxyz/tempo:
#
#   TEMPO_NODE_DIR  (default: ../tempo relative to this repo)
#
# Exit codes: 0 = no drift, 1 = drift detected, 2 = setup missing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TEMPO_STD_DIR="${TEMPO_STD_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"

exec python3 "$SCRIPT_DIR/check-drift.py" --node "${TEMPO_NODE_DIR:-}"
