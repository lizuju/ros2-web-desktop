# Jetson noVNC ROS 2 Desktop

This mode runs `rviz2`, `rqt`, and other ROS 2 GUI tools on the Jetson inside a local virtual desktop. Your Mac only opens a browser page, so it does not use SSH X11 forwarding.

For sharing this workflow with other Jetson users, see [DISTRIBUTING_JETSON_NOVNC.md](DISTRIBUTING_JETSON_NOVNC.md).
For local SSH tunnel commands on macOS, Linux, and Windows, see [LOCAL_TUNNEL.md](LOCAL_TUNNEL.md).

## Run on the Jetson

### Without Docker

Use this path if `docker` is not installed on the Jetson.

```bash
cd vnc-ros
cp .env.jetson.example .env
chmod +x scripts/install-jetson-novnc-system.sh scripts/start-jetson-novnc-system.sh
./scripts/install-jetson-novnc-system.sh
./scripts/start-jetson-novnc-system.sh
```

### With Docker

```bash
cd vnc-ros
cp .env.jetson.example .env
docker compose -f docker-compose.jetson-novnc.yml up --build
```

By default, noVNC listens only on the Jetson's `127.0.0.1`, so use an SSH tunnel from the local computer.

On macOS or Linux:

```bash
./scripts/open-jetson-novnc-tunnel.sh wheeltec@192.168.124.162
```

On Windows PowerShell:

```powershell
.\scripts\open-jetson-novnc-tunnel.ps1 wheeltec@192.168.124.162
```

Then open this from the local computer:

```text
http://localhost:8080/vnc.html
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
JETSON_ROS_SETUP=/home/wheeltec/wheeltec_ros2/install/setup.bash
```

## Custom Messages or Workspaces

If `rviz2` or `rqt` needs custom messages from the robot workspace, point `JETSON_ROS_WS` at that workspace before starting:

```bash
JETSON_ROS_WS=/home/wheeltec/wheeltec_ros2
docker compose -f docker-compose.jetson-novnc.yml up --build
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
ssh -L 8080:localhost:8080 wheeltec@<jetson-ip>
```

Then open:

```text
http://localhost:8080/vnc.html
```

This is HTTP tunneling for noVNC, not X11 forwarding.

## LAN Direct Access

If you intentionally want anyone on the same LAN to open the page directly, change `.env` on the Jetson:

```bash
NOVNC_LISTEN_HOST=0.0.0.0
```

Then restart `./scripts/start-jetson-novnc-system.sh` and open:

```text
http://<jetson-ip>:8080/vnc.html
```
