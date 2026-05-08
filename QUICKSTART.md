# Quick Start

Use this to view Jetson `rviz2`, `rqt`, and terminal windows from any computer with a browser.

## On the Jetson

Run this once:

```bash
git clone -b ros2-humble https://github.com/lizuju/vnc-ros.git
cd vnc-ros
./scripts/setup-jetson-novnc-system.sh
```

The setup script asks for `ROS_DOMAIN_ID`, the robot workspace setup file, and ports. Press Enter to accept the suggested values. The suggested ports are uncommon free ports, usually `31880` for noVNC and `31901` for the backend VNC server.

Start it:

```bash
cd ~/vnc-ros
./scripts/start-jetson-novnc-system.sh
```

Keep this terminal open.

## On the Local Computer

Open an SSH tunnel:

```bash
ssh -N -L 18080:127.0.0.1:<NOVNC_PORT> <jetson-user>@<jetson-ip>
```

Example:

```bash
ssh -N -L 18080:127.0.0.1:31880 wheeltec@192.168.124.162
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

Edit `.env` on the Jetson:

```bash
cd ~/vnc-ros
nano .env
```

Common settings:

```bash
ROS_DOMAIN_ID=7
JETSON_ROS_SETUP=/home/wheeltec/wheeltec_ros2/install/setup.bash
NOVNC_PORT=31880
VNC_PORT=31901
```

Restart `./scripts/start-jetson-novnc-system.sh`.
