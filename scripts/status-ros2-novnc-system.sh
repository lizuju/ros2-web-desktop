#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [ -f "${PROJECT_DIR}/.env" ]; then
  set -a
  source "${PROJECT_DIR}/.env"
  set +a
fi

DISPLAY="${DISPLAY:-:99}"
NOVNC_LISTEN_HOST="${NOVNC_LISTEN_HOST:-127.0.0.1}"
NOVNC_PORT="${NOVNC_PORT:-31880}"
VNC_PORT="${VNC_PORT:-31901}"
PID_FILE="${PROJECT_DIR}/logs/ros2-novnc.pids"

failures=0
warnings=0

pass() {
  echo "PASS $1"
}

warn() {
  warnings=$((warnings + 1))
  echo "WARN $1"
}

fail() {
  failures=$((failures + 1))
  echo "FAIL $1"
}

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

pid_from_file() {
  local name="$1"

  [ -f "$PID_FILE" ] || return
  awk -v name="$name" '$1 == name { print $2; exit }' "$PID_FILE"
}

pids_for_port() {
  local port="$1"

  ss -lntp 2>/dev/null \
    | awk -v port=":${port}" '$4 ~ port "$" { print }' \
    | sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p' \
    | sort -u
}

check_recorded_component() {
  local label="$1"
  local name="$2"
  local detail="$3"
  local pid

  pid="$(pid_from_file "$name" || true)"
  if [ -z "$pid" ]; then
    warn "${label}: not confirmed; pid file has no ${name} entry"
    return
  fi

  if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
    warn "${label}: invalid pid entry in ${PID_FILE}: ${pid}"
    return
  fi

  if ! pid_exists "$pid"; then
    warn "${label}: not running; recorded pid ${pid} is gone"
    return
  fi

  if matches_expected_process "$name" "$pid"; then
    pass "${label}: running (pid ${pid}${detail})"
  else
    warn "${label}: pid ${pid} is running but does not match this project"
    echo "  $(pid_args "$pid")"
  fi
}

check_port_component() {
  local label="$1"
  local name="$2"
  local port="$3"
  local detail="$4"
  local found=0
  local matched=0
  local pid

  for pid in $(pids_for_port "$port"); do
    found=1
    if matches_expected_process "$name" "$pid"; then
      matched=1
      pass "${label}: running (pid ${pid}${detail})"
    else
      fail "${label}: port ${port} is occupied by another process: pid ${pid}"
      echo "  $(pid_args "$pid")"
    fi
  done

  if [ "$found" -eq 0 ]; then
    warn "${label}: not listening on port ${port}"
  elif [ "$matched" -eq 0 ]; then
    echo "  Run ./scripts/stop-ros2-novnc-system.sh if this is an old ros2-web-desktop process, or change the port in .env."
  fi
}

echo "ros2-web-desktop status"
echo "Project: ${PROJECT_DIR}"
echo "Config: DISPLAY=${DISPLAY}, NOVNC_LISTEN_HOST=${NOVNC_LISTEN_HOST}, NOVNC_PORT=${NOVNC_PORT}, VNC_PORT=${VNC_PORT}"
if [ -f "$PID_FILE" ]; then
  echo "PID file: ${PID_FILE}"
else
  echo "PID file: missing (${PID_FILE})"
fi
echo

check_recorded_component "Xvfb" Xvfb ", DISPLAY=${DISPLAY}"
check_recorded_component "fluxbox" fluxbox ""
check_port_component "x11vnc" x11vnc "$VNC_PORT" ", VNC_PORT=${VNC_PORT}"
check_port_component "noVNC/websockify" websockify "$NOVNC_PORT" ", http://${NOVNC_LISTEN_HOST}:${NOVNC_PORT}/vnc.html"
check_recorded_component "xterm" xterm ""
echo

if [ "$failures" -gt 0 ]; then
  echo "Status found ${failures} failure(s) and ${warnings} warning(s)."
  echo "Next steps:"
  echo "  ./scripts/doctor-ros2-novnc-system.sh"
  echo "  ./scripts/stop-ros2-novnc-system.sh"
  echo "  ./scripts/start-ros2-novnc-system.sh"
  exit 1
fi

if [ "$warnings" -gt 0 ]; then
  echo "Status found ${warnings} warning(s). If the service is not running yet, start it with:"
  echo "  ./scripts/start-ros2-novnc-system.sh"
else
  echo "All tracked ros2-web-desktop components are running."
fi
