#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
  echo "Usage: $0 <user@jetson-ip> [local-port] [remote-port]"
  echo "Example: $0 wheeltec@192.168.124.162"
  exit 1
fi

TARGET="$1"
LOCAL_PORT="${2:-18080}"
REMOTE_PORT="${3:-31880}"

echo "Opening SSH tunnel:"
echo "  http://localhost:${LOCAL_PORT}/vnc.html -> ${TARGET}:127.0.0.1:${REMOTE_PORT}"
echo "Keep this terminal open. Press Ctrl+C to close the tunnel."

ssh -N -L "127.0.0.1:${LOCAL_PORT}:127.0.0.1:${REMOTE_PORT}" "$TARGET"
