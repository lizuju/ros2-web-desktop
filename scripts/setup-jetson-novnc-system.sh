#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$PROJECT_DIR"

if [ ! -f .env ]; then
  cp .env.jetson.example .env
fi

chmod +x scripts/*.sh

./scripts/install-jetson-novnc-system.sh

echo
echo "Setup complete."
echo "Start the Jetson desktop with:"
echo "  cd ${PROJECT_DIR}"
echo "  ./scripts/start-jetson-novnc-system.sh"
