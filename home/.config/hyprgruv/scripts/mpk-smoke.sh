#!/usr/bin/env bash
# mpk-smoke.sh — equipment check + pad learn for the MPK mini play.
#
#   mpk-smoke.sh           learn the 8+8 pads (Bank A then Bank B)
#   mpk-smoke.sh dump      live labeled readout
#   mpk-smoke.sh status    ports + current map
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/mpk-midi.py" "${1:-smoke}"
