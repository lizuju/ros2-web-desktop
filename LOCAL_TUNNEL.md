# Local SSH Tunnel for Jetson noVNC

Use this mode when the Jetson noVNC server is bound to `127.0.0.1`.
It prevents other machines on the LAN from opening `http://<jetson-ip>:8080`.

The Jetson must already be running:

```bash
cd ~/vnc-ros
./scripts/start-jetson-novnc-system.sh
```

## macOS and Linux

On the local computer:

```bash
./scripts/open-jetson-novnc-tunnel.sh wheeltec@192.168.124.162
```

Keep that terminal open, then browse to:

```text
http://localhost:8080/vnc.html
```

If the local computer does not have this repository, run the raw SSH command:

```bash
ssh -N -L 127.0.0.1:8080:127.0.0.1:8080 wheeltec@192.168.124.162
```

## Windows PowerShell

On the local computer:

```powershell
.\scripts\open-jetson-novnc-tunnel.ps1 wheeltec@192.168.124.162
```

Keep that PowerShell window open, then browse to:

```text
http://localhost:8080/vnc.html
```

If PowerShell blocks script execution, run the raw SSH command instead:

```powershell
ssh -N -L 127.0.0.1:8080:127.0.0.1:8080 wheeltec@192.168.124.162
```

## Custom Ports

If `8080` is already used locally:

```bash
./scripts/open-jetson-novnc-tunnel.sh wheeltec@192.168.124.162 18080 8080
```

Open:

```text
http://localhost:18080/vnc.html
```
