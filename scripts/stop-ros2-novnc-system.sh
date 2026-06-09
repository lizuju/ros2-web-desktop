#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

unset DISPLAY
if [ -f "${PROJECT_DIR}/.env" ]; then
  set -a
  source "${PROJECT_DIR}/.env"
  set +a
fi

export DISPLAY="${DISPLAY:-:99}"
export NOVNC_PORT="${NOVNC_PORT:-31880}"
export VNC_PORT="${VNC_PORT:-31901}"

PID_FILE="${PROJECT_DIR}/logs/ros2-novnc.pids"
stopped_count=0
missing_count=0
skipped_count=0
failed_count=0
seen_pids=""

pid_args() {
  ps -p "$1" -o args= 2>/dev/null || true
}

pid_exists() {
  ps -p "$1" >/dev/null 2>&1
}

matches_expected_process() {
  local name="$1"
  local pid="$2"
  local args

  args="$(pid_args "$pid")"
  case "$name" in
    Xtigervnc)
      [[ "$args" == *"Xtigervnc ${DISPLAY}"* && "$args" == *"-rfbport ${VNC_PORT}"* ]]
      ;;
    fluxbox)
      [[ "$args" == *"fluxbox"* ]]
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

already_seen_pid() {
  [[ " ${seen_pids} " == *" $1 "* ]]
}

mark_seen_pid() {
  seen_pids="${seen_pids} $1"
}

stop_pid() {
  local name="$1"
  local pid="$2"

  if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
    echo "Skip ${name}: invalid pid '${pid}'."
    skipped_count=$((skipped_count + 1))
    return
  fi

  if already_seen_pid "$pid"; then
    return
  fi
  mark_seen_pid "$pid"

  if ! pid_exists "$pid"; then
    echo "Not running: ${name} pid ${pid}."
    missing_count=$((missing_count + 1))
    return
  fi

  if ! matches_expected_process "$name" "$pid"; then
    echo "Skip ${name} pid ${pid}: command does not match this project."
    echo "  $(pid_args "$pid")"
    skipped_count=$((skipped_count + 1))
    return
  fi

  if kill "$pid" 2>/dev/null; then
    echo "Stopped ${name} pid ${pid}."
    stopped_count=$((stopped_count + 1))
  else
    echo "Could not stop ${name} pid ${pid}. If it is owned by another user, run:"
    echo "  sudo kill ${pid}"
    failed_count=$((failed_count + 1))
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
    stop_pid Xtigervnc "$pid"
  done
}

echo "ros2-web-desktop stop"
echo "Project: ${PROJECT_DIR}"
echo "Config: DISPLAY=${DISPLAY}, NOVNC_PORT=${NOVNC_PORT}, VNC_PORT=${VNC_PORT}"
echo "Scope: only matching ros2-web-desktop processes from the pid file or configured ports will be stopped."
echo

if [ -f "$PID_FILE" ]; then
  echo "Checking pid file: ${PID_FILE}"
  while read -r name pid; do
    stop_pid "$name" "$pid"
  done < "$PID_FILE"
else
  echo "PID file not found: ${PID_FILE}"
fi

echo "Checking configured ports."
stop_project_port_processes

if [ "$failed_count" -eq 0 ]; then
  rm -f "$PID_FILE"
else
  echo "PID file kept because some matching processes could not be stopped."
fi

echo
echo "Stop summary: stopped=${stopped_count}, already_gone=${missing_count}, skipped=${skipped_count}, failed=${failed_count}."
echo "Checked ports: NOVNC_PORT=${NOVNC_PORT}, VNC_PORT=${VNC_PORT}."

if [ "$stopped_count" -eq 0 ] && [ "$failed_count" -eq 0 ]; then
  echo "No matching ros2-web-desktop process needed stopping."
fi

if [ "$failed_count" -gt 0 ]; then
  exit 1
fi
