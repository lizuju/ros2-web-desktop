#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export PROJECT_DIR

if [ -f "${PROJECT_DIR}/.env" ]; then
  set -a
  source "${PROJECT_DIR}/.env"
  set +a
fi

export ROS_DISTRO="${ROS_DISTRO:-humble}"
export DISPLAY="${DISPLAY:-:99}"
export DISPLAY_WIDTH="${DISPLAY_WIDTH:-1440}"
export DISPLAY_HEIGHT="${DISPLAY_HEIGHT:-900}"
export DISPLAY_DEPTH="${DISPLAY_DEPTH:-24}"
export NOVNC_LISTEN_HOST="${NOVNC_LISTEN_HOST:-127.0.0.1}"
export NOVNC_PORT="${NOVNC_PORT:-31880}"
export VNC_PORT="${VNC_PORT:-31901}"
export ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-0}"
export ROS_LOCALHOST_ONLY="${ROS_LOCALHOST_ONLY:-0}"
export ROS_SETUP="${ROS_SETUP:-}"
export LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-1}"
export QT_X11_NO_MITSHM="${QT_X11_NO_MITSHM:-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-${USER}}"

if [ ! -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then
  echo "Missing /opt/ros/${ROS_DISTRO}/setup.bash"
  echo "Install ROS 2 ${ROS_DISTRO} on the remote Ubuntu / ROS 2 device first, or set ROS_DISTRO in .env."
  exit 1
fi

mkdir -p "$XDG_RUNTIME_DIR" "${PROJECT_DIR}/logs"
chmod 700 "$XDG_RUNTIME_DIR"

for cmd in Xvfb fluxbox x11vnc websockify xterm; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing command: ${cmd}"
    echo "Run: ./scripts/install-ros2-novnc-system.sh"
    exit 1
  fi
done

NOVNC_WEB_DIR=/usr/share/novnc
if [ ! -f "${NOVNC_WEB_DIR}/vnc.html" ]; then
  echo "Missing ${NOVNC_WEB_DIR}/vnc.html"
  echo "Run: ./scripts/install-ros2-novnc-system.sh"
  exit 1
fi

set +u
source "/opt/ros/${ROS_DISTRO}/setup.bash"
if [ -n "${ROS_SETUP}" ] && [ -f "${ROS_SETUP}" ]; then
  source "${ROS_SETUP}"
fi
if [ -f "${PROJECT_DIR}/ros2_ws/install/setup.bash" ]; then
  source "${PROJECT_DIR}/ros2_ws/install/setup.bash"
fi
set -u

pids=()
names=()
logs=()

cleanup() {
  if [ "${#pids[@]}" -gt 0 ]; then
    kill "${pids[@]}" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

Xvfb "$DISPLAY" -screen 0 "${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x${DISPLAY_DEPTH}" -ac +extension GLX +render -noreset >"${PROJECT_DIR}/logs/xvfb.log" 2>&1 &
pids+=("$!")
names+=("Xvfb")
logs+=("${PROJECT_DIR}/logs/xvfb.log")

sleep 1

fluxbox >"${PROJECT_DIR}/logs/fluxbox.log" 2>&1 &
pids+=("$!")
names+=("fluxbox")
logs+=("${PROJECT_DIR}/logs/fluxbox.log")

x11vnc -display "$DISPLAY" -forever -shared -nopw -listen 0.0.0.0 -rfbport "$VNC_PORT" >"${PROJECT_DIR}/logs/x11vnc.log" 2>&1 &
pids+=("$!")
names+=("x11vnc")
logs+=("${PROJECT_DIR}/logs/x11vnc.log")

websockify --web="${NOVNC_WEB_DIR}" "${NOVNC_LISTEN_HOST}:${NOVNC_PORT}" "127.0.0.1:${VNC_PORT}" >"${PROJECT_DIR}/logs/novnc.log" 2>&1 &
pids+=("$!")
names+=("websockify")
logs+=("${PROJECT_DIR}/logs/novnc.log")

xterm -title "ROS 2 Remote Desktop" -geometry 132x36+20+20 -e bash -lc 'source /opt/ros/${ROS_DISTRO}/setup.bash; [ -n "${ROS_SETUP}" ] && [ -f "${ROS_SETUP}" ] && source "${ROS_SETUP}"; [ -f "${PROJECT_DIR}/ros2_ws/install/setup.bash" ] && source "${PROJECT_DIR}/ros2_ws/install/setup.bash"; echo "ROS_DOMAIN_ID=${ROS_DOMAIN_ID}"; echo "Run: ros2 topic list"; echo "Run: rviz2"; echo "Run: rqt"; exec bash' >"${PROJECT_DIR}/logs/xterm.log" 2>&1 &

sleep 2

echo "noVNC is listening on port ${NOVNC_PORT}"
if [ "${NOVNC_LISTEN_HOST}" = "127.0.0.1" ] || [ "${NOVNC_LISTEN_HOST}" = "localhost" ]; then
  echo "Secure mode is enabled. Use SSH tunnel, then open http://localhost:${NOVNC_PORT}/vnc.html"
else
  echo "Open http://$(hostname -I | awk '{print $1}'):${NOVNC_PORT}/vnc.html from the local computer"
fi
echo "Press Ctrl+C here to stop it."

while sleep 5; do
  for i in "${!pids[@]}"; do
    pid="${pids[$i]}"
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "${names[$i]} exited. Recent log:"
      tail -80 "${logs[$i]}" 2>/dev/null || true
      exit 1
    fi
  done
done
