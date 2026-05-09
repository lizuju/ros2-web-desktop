# Ubuntu / ROS 2 noVNC Desktop

This mode runs `rviz2`, `rqt`, and other ROS 2 GUI tools on a remote Ubuntu / ROS 2 device inside a local virtual desktop. The local computer only opens a browser page, so it does not use SSH X11 forwarding.

For the shortest user flow, see [QUICKSTART.md](QUICKSTART.md).
For sharing this workflow with other users, see [DISTRIBUTING_ROS2_NOVNC.md](DISTRIBUTING_ROS2_NOVNC.md).
For local SSH tunnel commands on macOS, Linux, and Windows, see [LOCAL_TUNNEL.md](LOCAL_TUNNEL.md).

## Run on the Remote Device

### Without Docker

Use this path if `docker` is not installed on the remote device. For first-time setup:

```bash
cd ros2-web-desktop
./scripts/setup-ros2-novnc-system.sh
./scripts/start-ros2-novnc-system.sh
```

### With Docker

```bash
cd ros2-web-desktop
cp .env.ros2.example .env
docker compose -f docker-compose.ros2-novnc.yml up --build
```

By default, noVNC listens only on the remote device's `127.0.0.1`, so use an SSH tunnel from the local computer.

On macOS or Linux:

```bash
./scripts/open-ros2-novnc-tunnel.sh <device-user>@<device-host>
```

On Windows PowerShell:

```powershell
.\scripts\open-ros2-novnc-tunnel.ps1 <device-user>@<device-host>
```

Then open this from the local computer:

```text
http://localhost:18080/vnc.html
```

Click **Connect**. The desktop opens with a terminal already sourced for ROS 2.

## Launch ROS 2 GUI Tools

Inside the noVNC terminal:

```bash
ros2 topic list
rviz2
rqt
```

If the robot uses a non-zero ROS domain, edit `.env` before starting:

```bash
ROS_DOMAIN_ID=7
```

If the robot has a custom workspace, point `.env` at its setup file:

```bash
ROS_SETUP=/home/<user>/<robot_ws>/install/setup.bash
```

## Custom Messages or Workspaces

If `rviz2` or `rqt` needs custom messages from the robot workspace, point `ROS_WS` at that workspace before starting:

```bash
ROS_WS=/home/<user>/<robot_ws>
docker compose -f docker-compose.ros2-novnc.yml up --build
```

Then build/source as needed inside the noVNC terminal:

```bash
cd /root/ros2_ws
colcon build --symlink-install
source install/setup.bash
```

## Private Access Through SSH

Secure mode is the default. It tunnels only the web page:

```bash
ssh -L 18080:127.0.0.1:31880 <device-user>@<device-host>
```

Then open:

```text
http://localhost:18080/vnc.html
```

This is HTTP tunneling for noVNC, not X11 forwarding.

## LAN Direct Access

If you intentionally want anyone on the same LAN to open the page directly, change `.env` on the remote device:

```bash
NOVNC_LISTEN_HOST=0.0.0.0
```

Then restart `./scripts/start-ros2-novnc-system.sh` and open:

```text
http://<device-host>:31880/vnc.html
```
