#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[COPY] define.sh"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ define
