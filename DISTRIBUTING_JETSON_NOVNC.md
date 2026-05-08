# Distributing Jetson noVNC ROS 2 Desktop

Use this when giving the noVNC RViz/RQt workflow to another Jetson user.

For normal users, [QUICKSTART.md](QUICKSTART.md) is the shortest path.

## What the Jetson Needs

- Ubuntu with ROS 2 already installed, usually Humble on Ubuntu 22.04.
- Network access from the local computer to the Jetson.
- A user account with `sudo` for the one-time noVNC package install.
- The robot's ROS 2 workspace setup file path, if it has custom messages or launch files.

## What the Local Computer Needs

- A browser.
- SSH access to the Jetson for setup and optional tunneling.
- No XQuartz, X11 forwarding, Docker, or ROS install is required locally.

## One-Time Setup on the Jetson

Get the project onto the Jetson by cloning your published repo or copying the folder:

```bash
git clone -b ros2-humble https://github.com/lizuju/vnc-ros.git
cd vnc-ros
./scripts/setup-jetson-novnc-system.sh
```

The setup script asks for the robot-specific values and writes `.env`:

```bash
JETSON_ROS_SETUP=/home/wheeltec/wheeltec_ros2/install/setup.bash
ROS_DOMAIN_ID=0
VNC_PORT=31901
NOVNC_PORT=31880
NOVNC_LISTEN_HOST=127.0.0.1
```

## Start on the Jetson

```bash
cd ~/vnc-ros
./scripts/start-jetson-novnc-system.sh
```

Leave this terminal open. Stop it with `Ctrl+C`.

## Open from the Local Computer

Secure access is the default. On macOS or Linux:

```bash
./scripts/open-jetson-novnc-tunnel.sh <user>@<jetson-ip>
```

On Windows PowerShell:

```powershell
.\scripts\open-jetson-novnc-tunnel.ps1 <user>@<jetson-ip>
```

Then open:

```text
http://localhost:18080/vnc.html
```

If the local computer does not have this repository, use the raw SSH command:

```bash
ssh -L 18080:127.0.0.1:31880 <user>@<jetson-ip>
```

Then open:

```text
http://localhost:18080/vnc.html
```

This is noVNC over HTTP/WebSocket, not SSH X11 forwarding.

For direct LAN access, set this in `.env` on the Jetson:

```bash
NOVNC_LISTEN_HOST=0.0.0.0
```

Then open:

```text
http://<jetson-ip>:31880/vnc.html
```

## Use

Inside the browser desktop terminal:

```bash
ros2 topic list
rviz2
rqt
```

## Common Fixes

If the noVNC page opens but Connect fails, check whether the backend VNC port is already used:

```bash
ss -lntp | grep -E ':31880|:31901|:5900' || true
tail -n 80 logs/novnc.log logs/x11vnc.log logs/xvfb.log
```

If the chosen backend port is also occupied, change `VNC_PORT` in `.env`.
