# Local SSH Tunnel for Ubuntu / ROS 2 noVNC

Use this mode when the remote noVNC server is bound to `127.0.0.1`.
It prevents other machines on the LAN from opening the remote noVNC port directly.

The remote Ubuntu / ROS 2 device must already be running:

```bash
cd ~/vnc-ros
./scripts/start-ros2-novnc-system.sh
```

## macOS and Linux

On the local computer:

```bash
./scripts/open-ros2-novnc-tunnel.sh <device-user>@<device-host>
```

Keep that terminal open, then browse to:

```text
http://localhost:18080/vnc.html
```

If the local computer does not have this repository, run the raw SSH command:

```bash
ssh -N -L 127.0.0.1:18080:127.0.0.1:31880 <device-user>@<device-host>
```

## Windows PowerShell

On the local computer:

```powershell
.\scripts\open-ros2-novnc-tunnel.ps1 <device-user>@<device-host>
```

Keep that PowerShell window open, then browse to:

```text
http://localhost:18080/vnc.html
```

If PowerShell blocks script execution, run the raw SSH command instead:

```powershell
ssh -N -L 127.0.0.1:18080:127.0.0.1:31880 <device-user>@<device-host>
```

## Custom Ports

If `18080` is already used locally:

```bash
./scripts/open-ros2-novnc-tunnel.sh <device-user>@<device-host> 18081 31880
```

Open:

```text
http://localhost:18081/vnc.html
```
