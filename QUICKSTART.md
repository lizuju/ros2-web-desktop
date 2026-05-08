# Quick Start

Use this to view Jetson `rviz2`, `rqt`, and terminal windows from any computer with a browser.

## On the Jetson

Run this once:

```bash
git clone -b ros2-humble https://github.com/lizuju/vnc-ros.git
cd vnc-ros
./scripts/setup-jetson-novnc-system.sh
```

Start it:

```bash
cd ~/vnc-ros
./scripts/start-jetson-novnc-system.sh
```

Keep this terminal open.

## On the Local Computer

Open an SSH tunnel:

```bash
ssh -N -L 18080:127.0.0.1:8080 <jetson-user>@<jetson-ip>
```

Example:

```bash
ssh -N -L 18080:127.0.0.1:8080 wheeltec@192.168.124.162
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

## If the Robot Workspace Needs Sourcing

Edit `.env` on the Jetson:

```bash
cd ~/vnc-ros
nano .env
```

Set this to the robot workspace setup file:

```bash
JETSON_ROS_SETUP=/home/wheeltec/wheeltec_ros2/install/setup.bash
```

Restart `./scripts/start-jetson-novnc-system.sh`.
