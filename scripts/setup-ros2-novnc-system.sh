#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$PROJECT_DIR"

is_port_free() {
  local port="$1"
  ! ss -lnt 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${port}$"
}

find_free_port() {
  local port="$1"
  while ! is_port_free "$port"; do
    port=$((port + 1))
  done
  echo "$port"
}

read_value() {
  local prompt="$1"
  local default_value="$2"
  local value

  read -r -p "${prompt} [${default_value}]: " value
  echo "${value:-$default_value}"
}

read_port() {
  local prompt="$1"
  local default_value="$2"
  local value

  while true; do
    value="$(read_value "$prompt" "$default_value")"
    if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -gt 0 ] && [ "$value" -le 65535 ]; then
      echo "$value"
      return
    fi
    echo "Enter a port number from 1 to 65535." >&2
  done
}

if [ ! -f .env ]; then
  cp .env.ros2.example .env
fi

default_novnc_port="$(find_free_port 31880)"
default_vnc_port="$(find_free_port 31901)"

echo "Configure Ubuntu / ROS 2 noVNC remote desktop."
echo "Press Enter to accept the suggested value."
echo

ros_domain_id="$(read_value "ROS_DOMAIN_ID" "0")"
ros_setup="$(read_value "Absolute robot workspace setup file, or leave empty" "")"
novnc_port="$(read_port "noVNC web port" "$default_novnc_port")"
while ! is_port_free "$novnc_port"; do
  echo "Port ${novnc_port} is already in use."
  novnc_port="$(read_port "noVNC web port" "$(find_free_port "$((novnc_port + 1))")")"
done

vnc_port="$(read_port "Internal VNC backend port" "$default_vnc_port")"
while [ "$vnc_port" = "$novnc_port" ] || ! is_port_free "$vnc_port"; do
  if [ "$vnc_port" = "$novnc_port" ]; then
    echo "Internal VNC backend port must be different from the noVNC web port."
  else
    echo "Port ${vnc_port} is already in use."
  fi
  vnc_port="$(read_port "Internal VNC backend port" "$(find_free_port "$((vnc_port + 1))")")"
done

tmp_env="$(mktemp)"
awk -v ros_domain_id="$ros_domain_id" \
    -v ros_setup="$ros_setup" \
    -v novnc_port="$novnc_port" \
    -v vnc_port="$vnc_port" \
    -v novnc_listen_host="127.0.0.1" \
    'BEGIN {
       seen_ros_domain_id = 0
       seen_ros_setup = 0
       seen_novnc_port = 0
       seen_vnc_port = 0
       seen_novnc_listen_host = 0
     }
     /^ROS_DOMAIN_ID=/ { print "ROS_DOMAIN_ID=" ros_domain_id; seen_ros_domain_id = 1; next }
     /^ROS_SETUP=/ { print "ROS_SETUP=" ros_setup; seen_ros_setup = 1; next }
     /^NOVNC_PORT=/ { print "NOVNC_PORT=" novnc_port; seen_novnc_port = 1; next }
     /^VNC_PORT=/ { print "VNC_PORT=" vnc_port; seen_vnc_port = 1; next }
     /^NOVNC_LISTEN_HOST=/ { print "NOVNC_LISTEN_HOST=" novnc_listen_host; seen_novnc_listen_host = 1; next }
     { print }
     END {
       if (!seen_ros_domain_id) print "ROS_DOMAIN_ID=" ros_domain_id
       if (!seen_ros_setup) print "ROS_SETUP=" ros_setup
       if (!seen_novnc_port) print "NOVNC_PORT=" novnc_port
       if (!seen_vnc_port) print "VNC_PORT=" vnc_port
       if (!seen_novnc_listen_host) print "NOVNC_LISTEN_HOST=" novnc_listen_host
     }' .env > "$tmp_env"
mv "$tmp_env" .env

chmod +x scripts/*.sh

./scripts/install-ros2-novnc-system.sh

echo
echo "Setup complete."
echo "Configured .env:"
echo "  ROS_DOMAIN_ID=${ros_domain_id}"
echo "  ROS_SETUP=${ros_setup}"
echo "  NOVNC_PORT=${novnc_port}"
echo "  VNC_PORT=${vnc_port}"
echo "Check the remote ROS 2 desktop with:"
echo "  cd ${PROJECT_DIR}"
echo "  ./scripts/doctor-ros2-novnc-system.sh"
echo "Start the remote ROS 2 desktop with:"
echo "  cd ${PROJECT_DIR}"
echo "  ./scripts/start-ros2-novnc-system.sh"
echo "Stop it later with:"
echo "  ./scripts/stop-ros2-novnc-system.sh"
echo
echo "Open a tunnel from the local computer with:"
echo "  ssh -N -L 18080:127.0.0.1:${novnc_port} <device-user>@<device-host>"
echo
echo "Then open:"
echo "  http://localhost:18080/vnc.html"
