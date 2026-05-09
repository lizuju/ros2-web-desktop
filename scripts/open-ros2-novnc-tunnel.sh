#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
  echo "Usage: $0 <user@device-host> [local-port] [remote-port]"
  echo "Example: $0 <device-user>@<device-host>"
  echo "Optional: REMOTE_PROJECT_DIR=/path/to/ros2-web-desktop $0 <device-user>@<device-host>"
  exit 1
fi

TARGET="$1"
LOCAL_PORT="${2:-18080}"
REMOTE_PORT="${3:-}"
REMOTE_PROJECT_DIR="${REMOTE_PROJECT_DIR:-~/ros2-web-desktop}"

is_local_port_free() {
  local port="$1"

  if command -v lsof >/dev/null 2>&1; then
    ! lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
  elif command -v ss >/dev/null 2>&1; then
    ! ss -lnt 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${port}$"
  else
    return 0
  fi
}

find_free_local_port() {
  local port="$1"

  while ! is_local_port_free "$port"; do
    port=$((port + 1))
  done
  echo "$port"
}

shell_quote() {
  printf "'%s'" "$(printf "%s" "$1" | sed "s/'/'\\\\''/g")"
}

read_remote_port() {
  local quoted_project_dir
  quoted_project_dir="$(shell_quote "$REMOTE_PROJECT_DIR")"

  ssh "$TARGET" "PROJECT_DIR=${quoted_project_dir}; case \"\$PROJECT_DIR\" in ~/*) PROJECT_DIR=\"\$HOME/\${PROJECT_DIR#~/}\";; esac; if [ -f \"\$PROJECT_DIR/.env\" ]; then sed -n 's/^NOVNC_PORT=//p' \"\$PROJECT_DIR/.env\" | tail -n 1; fi" 2>/dev/null || true
}

open_url_when_ready() {
  local url="$1"
  local port="$2"
  local i=0

  while [ "$i" -lt 60 ]; do
    if ! is_local_port_free "$port"; then
      if command -v open >/dev/null 2>&1; then
        open "$url" >/dev/null 2>&1 || true
      elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url" >/dev/null 2>&1 || true
      else
        echo "Open: $url"
      fi
      return
    fi
    i=$((i + 1))
    sleep 1
  done

  echo "Open: $url"
}

LOCAL_PORT="$(find_free_local_port "$LOCAL_PORT")"

if [ -z "$REMOTE_PORT" ]; then
  REMOTE_PORT="$(read_remote_port)"
  if [ -z "$REMOTE_PORT" ]; then
    echo "Could not read NOVNC_PORT from ${TARGET}:${REMOTE_PROJECT_DIR}/.env"
    echo "Pass the remote port explicitly, or set REMOTE_PROJECT_DIR."
    echo "Example: $0 ${TARGET} ${LOCAL_PORT} 31880"
    exit 1
  fi
fi

URL="http://localhost:${LOCAL_PORT}/vnc.html"

echo "Opening SSH tunnel:"
echo "  ${URL} -> ${TARGET}:127.0.0.1:${REMOTE_PORT}"
echo "Remote project directory: ${REMOTE_PROJECT_DIR}"
echo "Keep this terminal open. Press Ctrl+C to close the tunnel."

open_url_when_ready "$URL" "$LOCAL_PORT" &

ssh -N -o ExitOnForwardFailure=yes -L "127.0.0.1:${LOCAL_PORT}:127.0.0.1:${REMOTE_PORT}" "$TARGET"
