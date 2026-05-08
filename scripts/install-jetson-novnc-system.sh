#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  dbus-x11 \
  fluxbox \
  libgl1-mesa-dri \
  libglx-mesa0 \
  mesa-utils \
  novnc \
  websockify \
  x11vnc \
  xterm \
  xvfb
