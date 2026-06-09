#!/usr/bin/env bash
set -euo pipefail

export DISPLAY="${DISPLAY:-:99}"
export DISPLAY_WIDTH="${DISPLAY_WIDTH:-1440}"
export DISPLAY_HEIGHT="${DISPLAY_HEIGHT:-900}"
export DISPLAY_DEPTH="${DISPLAY_DEPTH:-24}"
export NOVNC_LISTEN_HOST="${NOVNC_LISTEN_HOST:-127.0.0.1}"
export NOVNC_PORT="${NOVNC_PORT:-31880}"
export VNC_PORT="${VNC_PORT:-31901}"
export ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-0}"
export ROS_LOCALHOST_ONLY="${ROS_LOCALHOST_ONLY:-0}"
export RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_fastrtps_cpp}"
export LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-1}"
export QT_X11_NO_MITSHM="${QT_X11_NO_MITSHM:-1}"
export NO_AT_BRIDGE="${NO_AT_BRIDGE:-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-root}"

mkdir -p "$XDG_RUNTIME_DIR" /root/ros2_ws/src /tmp/ros2-novnc
chmod 700 "$XDG_RUNTIME_DIR"

NOVNC_WEB_DIR=/usr/share/novnc
if [ ! -f "${NOVNC_WEB_DIR}/vnc.html" ]; then
  echo "Missing ${NOVNC_WEB_DIR}/vnc.html"
  exit 1
fi

set +u
source "/opt/ros/${ROS_DISTRO}/setup.bash"
if [ -f /root/ros2_ws/install/setup.bash ]; then
  source /root/ros2_ws/install/setup.bash
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

Xtigervnc "$DISPLAY" -geometry "${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}" -depth "$DISPLAY_DEPTH" -rfbport "$VNC_PORT" -localhost -SecurityTypes None >/tmp/ros2-novnc/tigervnc.log 2>&1 &
pids+=("$!")
names+=("Xtigervnc")
logs+=("/tmp/ros2-novnc/tigervnc.log")

sleep 1

fluxbox >/tmp/ros2-novnc/fluxbox.log 2>&1 &
pids+=("$!")
names+=("fluxbox")
logs+=("/tmp/ros2-novnc/fluxbox.log")

websockify --web="${NOVNC_WEB_DIR}" "${NOVNC_LISTEN_HOST}:${NOVNC_PORT}" "127.0.0.1:${VNC_PORT}" >/tmp/ros2-novnc/novnc.log 2>&1 &
pids+=("$!")
names+=("websockify")
logs+=("/tmp/ros2-novnc/novnc.log")

xterm -title "ROS 2 Remote Desktop" -geometry 132x36+20+20 -e bash -lc 'source /opt/ros/${ROS_DISTRO}/setup.bash; [ -f /root/ros2_ws/install/setup.bash ] && source /root/ros2_ws/install/setup.bash; echo "ROS_DOMAIN_ID=${ROS_DOMAIN_ID}"; echo "Run: ros2 topic list"; echo "Run: rviz2"; echo "Run: rqt"; exec bash' >/tmp/ros2-novnc/xterm.log 2>&1 &

echo "noVNC is listening on port ${NOVNC_PORT}"
if [ "${NOVNC_LISTEN_HOST}" = "127.0.0.1" ] || [ "${NOVNC_LISTEN_HOST}" = "localhost" ]; then
  echo "Secure mode is enabled. Use SSH tunnel, then open http://localhost:${NOVNC_PORT}/vnc.html"
else
  echo "Open http://<device-host>:${NOVNC_PORT}/vnc.html from the local computer"
fi

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
