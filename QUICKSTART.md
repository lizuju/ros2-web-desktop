# Quick Start

Use this to view remote Ubuntu / ROS 2 `rviz2`, `rqt`, and terminal windows from any computer with a browser. It does not use X11 forwarding.

## On the Remote Ubuntu / ROS 2 Device

Run this once:

```bash
git clone -b ros2-humble https://github.com/lizuju/ros2-web-desktop.git
cd ros2-web-desktop
./scripts/setup-ros2-novnc-system.sh
```

The setup script asks for `ROS_DOMAIN_ID`, the robot workspace setup file, and ports. Press Enter to accept the suggested values. The suggested ports are uncommon free ports, usually `31880` for noVNC and `31901` for the backend VNC server.

Start it:

```bash
cd ~/ros2-web-desktop
./scripts/start-ros2-novnc-system.sh
```

Keep this terminal open.

## On the Local Computer

Open an SSH tunnel:

```bash
ssh -N -L 18080:127.0.0.1:<NOVNC_PORT> <device-user>@<device-host>
```

Example:

```bash
ssh -N -L 18080:127.0.0.1:31880 <device-user>@<device-host>
```

Keep this terminal open, then browse to:

```text
http://localhost:18080/vnc.html
```

## Use

Inside the browser desktop terminal:

```bash
rviz2
rqt
```

## Change Settings Later

Edit `.env` on the remote device:

```bash
cd ~/ros2-web-desktop
nano .env
```

Common settings:

```bash
ROS_DOMAIN_ID=7
ROS_SETUP=/home/<user>/<robot_ws>/install/setup.bash
NOVNC_PORT=31880
VNC_PORT=31901
```

Restart `./scripts/start-ros2-novnc-system.sh`.
