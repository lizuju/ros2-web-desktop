#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

unset DISPLAY
if [ -f "${PROJECT_DIR}/.env" ]; then
  set -a
  source "${PROJECT_DIR}/.env"
  set +a
fi

ROS_DISTRO="${ROS_DISTRO:-humble}"
DISPLAY="${DISPLAY:-:99}"
NOVNC_LISTEN_HOST="${NOVNC_LISTEN_HOST:-127.0.0.1}"
NOVNC_PORT="${NOVNC_PORT:-31880}"
VNC_PORT="${VNC_PORT:-31901}"
ROS_SETUP="${ROS_SETUP:-}"
PID_FILE="${PROJECT_DIR}/logs/ros2-novnc.pids"
NOVNC_WEB_DIR=/usr/share/novnc

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

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "command found: $1"
  else
    fail "missing command: $1"
  fi
}

pid_args() {
  ps -p "$1" -o args= 2>/dev/null || true
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

pids_for_port() {
  local port="$1"
  ss -lntp 2>/dev/null \
    | awk -v port=":${port}" '$4 ~ port "$" { print }' \
    | sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p' \
    | sort -u
}

check_port() {
  local label="$1"
  local port="$2"
  local expected_name="$3"
  local found=0
  local matched=0
  local pid

  for pid in $(pids_for_port "$port"); do
    found=1
    if matches_expected_process "$expected_name" "$pid"; then
      matched=1
      pass "${label} port ${port} is used by this project (${expected_name} pid ${pid})"
    else
      fail "${label} port ${port} is occupied by another process: pid ${pid} $(pid_args "$pid")"
    fi
  done

  if [ "$found" -eq 0 ]; then
    warn "${label} port ${port} is free; ${expected_name} is not listening yet"
  elif [ "$matched" -eq 0 ]; then
    echo "  Suggestion: change the port in .env, or stop the conflicting process."
  fi
}

check_pid_file() {
  local name
  local pid

  if [ ! -f "$PID_FILE" ]; then
    warn "pid file not found: ${PID_FILE}; service may not be running"
    return
  fi

  while read -r name pid; do
    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
      warn "invalid pid entry in ${PID_FILE}: ${name} ${pid}"
    elif ! kill -0 "$pid" 2>/dev/null; then
      warn "${name} pid ${pid} is not running"
    elif matches_expected_process "$name" "$pid"; then
      pass "${name} pid ${pid} is running"
    else
      warn "${name} pid ${pid} is running but does not match this project"
    fi
  done < "$PID_FILE"
}

echo "ros2-web-desktop doctor"
echo "Project: ${PROJECT_DIR}"
echo
echo "Configuration:"
echo "  ROS_DISTRO=${ROS_DISTRO}"
echo "  ROS_SETUP=${ROS_SETUP}"
echo "  ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}"
echo "  DISPLAY=${DISPLAY}"
echo "  NOVNC_LISTEN_HOST=${NOVNC_LISTEN_HOST}"
echo "  NOVNC_PORT=${NOVNC_PORT}"
echo "  VNC_PORT=${VNC_PORT}"
echo

for cmd in Xtigervnc fluxbox websockify xterm ss; do
  check_command "$cmd"
done

if [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then
  pass "ROS setup found: /opt/ros/${ROS_DISTRO}/setup.bash"
else
  fail "missing ROS setup: /opt/ros/${ROS_DISTRO}/setup.bash"
fi

if [ -n "$ROS_SETUP" ]; then
  if [ -f "$ROS_SETUP" ]; then
    pass "workspace setup found: ${ROS_SETUP}"
  else
    fail "workspace setup not found: ${ROS_SETUP}"
  fi
else
  warn "ROS_SETUP is empty; only /opt/ros/${ROS_DISTRO}/setup.bash will be sourced"
fi

if [ -f "${NOVNC_WEB_DIR}/vnc.html" ]; then
  pass "noVNC web file found: ${NOVNC_WEB_DIR}/vnc.html"
else
  fail "missing noVNC web file: ${NOVNC_WEB_DIR}/vnc.html"
fi

if [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then
  set +u
  source "/opt/ros/${ROS_DISTRO}/setup.bash" >/dev/null 2>&1 || true
  if [ -n "${ROS_SETUP}" ] && [ -f "${ROS_SETUP}" ]; then
    source "${ROS_SETUP}" >/dev/null 2>&1 || true
  fi
  if [ -f "${PROJECT_DIR}/ros2_ws/install/setup.bash" ]; then
    source "${PROJECT_DIR}/ros2_ws/install/setup.bash" >/dev/null 2>&1 || true
  fi
  set -u
fi

check_command ros2
echo

check_port "noVNC" "$NOVNC_PORT" websockify
check_port "TigerVNC backend" "$VNC_PORT" Xtigervnc
check_pid_file
echo

if [ "$failures" -gt 0 ]; then
  echo "Doctor found ${failures} failure(s) and ${warnings} warning(s)."
  echo "Suggested next steps:"
  echo "  ./scripts/install-ros2-novnc-system.sh"
  echo "  ./scripts/stop-ros2-novnc-system.sh"
  echo "  ./scripts/start-ros2-novnc-system.sh"
  exit 1
fi

if [ "$warnings" -gt 0 ]; then
  echo "Doctor found ${warnings} warning(s), but no hard failures."
  echo "If the service is not running yet, start it with:"
  echo "  ./scripts/start-ros2-novnc-system.sh"
else
  echo "Doctor checks passed."
fi
