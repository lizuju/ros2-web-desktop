#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [ -f "${PROJECT_DIR}/.env" ]; then
  set -a
  source "${PROJECT_DIR}/.env"
  set +a
fi

export DISPLAY="${DISPLAY:-:99}"
export NOVNC_PORT="${NOVNC_PORT:-31880}"
export VNC_PORT="${VNC_PORT:-31901}"

PID_FILE="${PROJECT_DIR}/logs/ros2-novnc.pids"

pid_args() {
  ps -p "$1" -o args= 2>/dev/null || true
}

matches_expected_process() {
  local name="$1"
  local pid="$2"
  local args

  args="$(pid_args "$pid")"
  case "$name" in
    Xvfb)
      [[ "$args" == *"Xvfb ${DISPLAY}"* ]]
      ;;
    fluxbox)
      [[ "$args" == *"fluxbox"* ]]
      ;;
    x11vnc)
      [[ "$args" == *"x11vnc"* && "$args" == *"-rfbport ${VNC_PORT}"* ]]
      ;;
    websockify)
      [[ "$args" == *"websockify"* && "$args" == *":${NOVNC_PORT}"* && "$args" == *"127.0.0.1:${VNC_PORT}"* ]]
      ;;
    xterm)
      [[ "$args" == *"xterm"* && "$args" == *"ROS 2 Remote Desktop"* ]]
      ;;
    *)
      return 1
      ;;
  esac
}

stop_pid() {
  local name="$1"
  local pid="$2"

  if ! [[ "$pid" =~ ^[0-9]+$ ]] || ! kill -0 "$pid" 2>/dev/null; then
    return
  fi

  if ! matches_expected_process "$name" "$pid"; then
    echo "Skip ${pid}: not a matching ${name} process."
    return
  fi

  if kill "$pid" 2>/dev/null; then
    echo "Stopped ${name} pid ${pid}."
  else
    echo "Could not stop ${name} pid ${pid}. If it is owned by another user, run:"
    echo "  sudo kill ${pid}"
  fi
}

pids_for_port() {
  local port="$1"
  ss -lntp 2>/dev/null \
    | awk -v port=":${port}" '$4 ~ port "$" { print }' \
    | sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p' \
    | sort -u
}

stop_project_port_processes() {
  local pid

  for pid in $(pids_for_port "$NOVNC_PORT"); do
    stop_pid websockify "$pid"
  done

  for pid in $(pids_for_port "$VNC_PORT"); do
    stop_pid x11vnc "$pid"
  done
}

if [ -f "$PID_FILE" ]; then
  while read -r name pid; do
    stop_pid "$name" "$pid"
  done < "$PID_FILE"
  rm -f "$PID_FILE"
fi

stop_project_port_processes

echo "Checked ros2-web-desktop ports: NOVNC_PORT=${NOVNC_PORT}, VNC_PORT=${VNC_PORT}."
