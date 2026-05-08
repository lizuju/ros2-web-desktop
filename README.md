# vnc-ros | Jetson noVNC ROS 2 Desktop

## 中文说明

### 这个项目有什么用

`vnc-ros` 用来在 **Mac、Linux、Windows 的浏览器里查看和操作远程 Jetson 上的 ROS 2 图形界面**，例如：

- `rviz2`
- `rqt`
- `rqt_graph`
- `rqt_image_view`
- Jetson 上的图形终端

图形程序实际运行在 Jetson 上，本地电脑只打开网页画面。这样可以避免 Mac Apple Silicon 上使用 X11 转发 / XQuartz 时比较卡的问题。

本地电脑不需要安装：

- ROS 2
- RViz
- rqt
- Docker
- XQuartz
- VNC 客户端

本地电脑只需要：

- 浏览器
- `ssh` 命令
- 能通过网络访问 Jetson

### 工作方式

Jetson 上启动一个轻量虚拟桌面：

- `Xvfb` 提供虚拟显示器
- `fluxbox` 提供窗口管理器
- `x11vnc` 把虚拟桌面变成 VNC
- `websockify` / noVNC 把 VNC 变成浏览器页面
- `rviz2`、`rqt` 等程序在 Jetson 本机运行

默认安全模式下，noVNC 只监听 Jetson 自己的 `127.0.0.1`，外部电脑不能直接打开 Jetson 的端口。用户通过 SSH 隧道访问：

```text
本地浏览器 -> 本地 localhost:18080 -> SSH 隧道 -> Jetson 127.0.0.1:<NOVNC_PORT>
```

### Jetson 端要求

- Ubuntu，并已安装 ROS 2，通常是 Ubuntu 22.04 + ROS 2 Humble
- 能执行 `sudo apt-get`
- 已开启 SSH
- 用户知道机器人 ROS 工作区的 `install/setup.bash` 路径，如果有自定义消息、launch 文件或机器人包

### 本地电脑要求

Mac / Linux:

- 系统一般自带 `ssh`
- 使用任意现代浏览器

Windows:

- PowerShell 或 Windows Terminal
- Windows 自带 OpenSSH，若没有则需要启用 OpenSSH Client
- 使用任意现代浏览器

### Jetson 第一次安装配置

在 Jetson 上运行：

```bash
git clone -b ros2-humble https://github.com/lizuju/vnc-ros.git
cd vnc-ros
./scripts/setup-jetson-novnc-system.sh
```

安装脚本会自动做这些事：

- 如果没有 `.env`，自动从 `.env.jetson.example` 创建
- 询问 `ROS_DOMAIN_ID`
- 询问机器人工作区 setup 文件路径，例如 `/home/wheeltec/wheeltec_ros2/install/setup.bash`
- 自动推荐不常见且未占用的端口，通常从 `31880` 和 `31901` 开始找
- 检查端口是否有效、是否被占用、两个端口是否冲突
- 安装 `xvfb`、`fluxbox`、`x11vnc`、`novnc`、`websockify`、`xterm` 等依赖
- 输出本地电脑需要执行的 SSH 隧道命令

脚本中的常见问题应该这样填：

```text
ROS_DOMAIN_ID:
  填机器人 ROS 2 使用的 domain id。若不知道，先用 0。

Absolute robot workspace setup file:
  如果机器人工作区需要 source，填写绝对路径。
  例如 /home/wheeltec/wheeltec_ros2/install/setup.bash
  如果不需要，直接回车。

noVNC web port:
  Jetson 上的 noVNC 网页端口。建议直接回车使用推荐值。

Internal VNC backend port:
  Jetson 内部 VNC 后端端口。建议直接回车使用推荐值。
```

### Jetson 每次启动

在 Jetson 上运行：

```bash
cd ~/vnc-ros
./scripts/start-jetson-novnc-system.sh
```

保持这个终端不要关闭。看到类似输出后，说明 Jetson 端已经启动：

```text
noVNC is listening on port 31880
Secure mode is enabled. Use SSH tunnel, then open http://localhost:31880/vnc.html
Press Ctrl+C here to stop it.
```

注意：浏览器不要直接打开 Jetson 输出里的 `localhost:31880`。那是 Jetson 自己的本地地址。本地电脑需要先开 SSH 隧道。

### 本地电脑访问

在本地电脑打开一个新终端，执行：

```bash
ssh -N -L 18080:127.0.0.1:<NOVNC_PORT> <jetson-user>@<jetson-ip>
```

例如 Jetson IP 是 `192.168.124.162`，用户名是 `wheeltec`，setup 脚本推荐的 `NOVNC_PORT` 是 `31880`：

```bash
ssh -N -L 18080:127.0.0.1:31880 wheeltec@192.168.124.162
```

输入 Jetson 密码后，这个终端会停在那里，这是正常的。保持它不要关闭。

然后打开浏览器：

```text
http://localhost:18080/vnc.html
```

点击 **Connect**，就能进入 Jetson 上的图形桌面。

### 在网页桌面里使用

网页桌面里的终端是在 Jetson 上运行的，可以执行：

```bash
ros2 topic list
ros2 node list
rviz2
rqt
rqt_graph
rqt_image_view
```

启动的图形程序会显示在浏览器里的 noVNC 桌面中。

### 端口说明

SSH 隧道命令格式：

```bash
ssh -N -L 本地端口:127.0.0.1:Jetson端口 用户名@JetsonIP
```

例如：

```bash
ssh -N -L 18080:127.0.0.1:31880 wheeltec@192.168.124.162
```

含义：

```text
18080:
  本地电脑端口。浏览器打开 localhost:18080。
  如果本地 18080 被占用，可以换成 18081、28080 等。

31880:
  Jetson 上 noVNC 的端口。由 setup 脚本写入 .env 的 NOVNC_PORT。
```

如果本地 `18080` 被占用，可以这样换成本地 `18081`：

```bash
ssh -N -L 18081:127.0.0.1:31880 wheeltec@192.168.124.162
```

然后浏览器打开：

```text
http://localhost:18081/vnc.html
```

### 修改配置

在 Jetson 上编辑 `.env`：

```bash
cd ~/vnc-ros
nano .env
```

常见配置：

```bash
ROS_DOMAIN_ID=7
JETSON_ROS_SETUP=/home/wheeltec/wheeltec_ros2/install/setup.bash
NOVNC_LISTEN_HOST=127.0.0.1
NOVNC_PORT=31880
VNC_PORT=31901
```

修改后重启：

```bash
./scripts/start-jetson-novnc-system.sh
```

### 直接局域网访问

默认不建议直接暴露 noVNC 到局域网。如果确实需要让同一局域网用户直接打开 Jetson 地址，可以在 Jetson 的 `.env` 中设置：

```bash
NOVNC_LISTEN_HOST=0.0.0.0
```

然后重启服务，浏览器打开：

```text
http://<jetson-ip>:<NOVNC_PORT>/vnc.html
```

注意：这样同一局域网中知道地址和端口的人都可能打开这个桌面。只在可信网络使用。

### 停止服务

在运行 `start-jetson-novnc-system.sh` 的 Jetson 终端按：

```text
Ctrl+C
```

如果异常退出后端口仍被占用，可以在 Jetson 上清理：

```bash
pkill -f websockify || true
pkill -f x11vnc || true
pkill -f Xvfb || true
```

### 常见问题

如果 noVNC 页面打不开：

```bash
cd ~/vnc-ros
ss -lntp | grep -E ':31880|:31901|:5900' || true
tail -n 80 logs/novnc.log logs/x11vnc.log logs/xvfb.log
```

如果页面能打开但点击 Connect 失败，通常是后端 VNC 端口冲突。修改 `.env` 里的 `VNC_PORT`，再重启。

如果 `rviz2` 看不到机器人 topic：

- 检查 `ROS_DOMAIN_ID` 是否和机器人一致
- 检查 `JETSON_ROS_SETUP` 是否指向正确工作区
- 在网页终端里运行 `ros2 topic list`

如果本地 `ssh -L` 提示 `Address already in use`：

- 换一个本地端口，例如把 `18080` 改成 `18081`
- 浏览器也相应打开 `http://localhost:18081/vnc.html`

### 其他文档

- [QUICKSTART.md](QUICKSTART.md): 最短使用流程
- [LOCAL_TUNNEL.md](LOCAL_TUNNEL.md): Mac、Linux、Windows 的 SSH 隧道说明
- [JETSON_NOVNC.md](JETSON_NOVNC.md): Jetson noVNC 细节
- [DISTRIBUTING_JETSON_NOVNC.md](DISTRIBUTING_JETSON_NOVNC.md): 分发给其他用户时的说明

---

## English Guide

### What This Project Does

`vnc-ros` lets you view and operate ROS 2 GUI tools running on a remote Jetson from a browser on **macOS, Linux, or Windows**. Typical tools include:

- `rviz2`
- `rqt`
- `rqt_graph`
- `rqt_image_view`
- a graphical terminal on the Jetson

The GUI applications run on the Jetson. The local computer only receives a browser-based desktop stream. This avoids slow SSH X11 forwarding / XQuartz workflows, especially on Apple Silicon Macs.

The local computer does not need:

- ROS 2
- RViz
- rqt
- Docker
- XQuartz
- a native VNC client

The local computer only needs:

- a browser
- the `ssh` command
- network access to the Jetson

### How It Works

The Jetson starts a lightweight virtual desktop:

- `Xvfb` provides a virtual display
- `fluxbox` provides a window manager
- `x11vnc` exposes the virtual desktop as VNC
- `websockify` / noVNC exposes VNC as a browser page
- `rviz2`, `rqt`, and other GUI tools run locally on the Jetson

In the default secure mode, noVNC listens only on the Jetson's `127.0.0.1`. Other machines cannot open the noVNC port directly. Users access it through an SSH tunnel:

```text
local browser -> local localhost:18080 -> SSH tunnel -> Jetson 127.0.0.1:<NOVNC_PORT>
```

### Jetson Requirements

- Ubuntu with ROS 2 installed, usually Ubuntu 22.04 + ROS 2 Humble
- `sudo apt-get` access
- SSH enabled
- the robot workspace `install/setup.bash` path, if custom messages, launch files, or robot packages are needed

### Local Computer Requirements

Mac / Linux:

- `ssh` is usually built in
- any modern browser

Windows:

- PowerShell or Windows Terminal
- OpenSSH Client enabled
- any modern browser

### First-Time Setup on the Jetson

Run this on the Jetson:

```bash
git clone -b ros2-humble https://github.com/lizuju/vnc-ros.git
cd vnc-ros
./scripts/setup-jetson-novnc-system.sh
```

The setup script will:

- create `.env` from `.env.jetson.example` if missing
- ask for `ROS_DOMAIN_ID`
- ask for the robot workspace setup file, such as `/home/wheeltec/wheeltec_ros2/install/setup.bash`
- suggest uncommon free ports, usually starting from `31880` and `31901`
- validate port values and avoid occupied/conflicting ports
- install `xvfb`, `fluxbox`, `x11vnc`, `novnc`, `websockify`, `xterm`, and related dependencies
- print the SSH tunnel command to run on the local computer

Prompt guidance:

```text
ROS_DOMAIN_ID:
  Use the same ROS 2 domain ID as the robot. If unsure, start with 0.

Absolute robot workspace setup file:
  Enter the absolute setup path if the robot workspace needs sourcing.
  Example: /home/wheeltec/wheeltec_ros2/install/setup.bash
  Press Enter if not needed.

noVNC web port:
  The Jetson noVNC web port. Press Enter to accept the suggested free port.

Internal VNC backend port:
  The Jetson internal VNC backend port. Press Enter to accept the suggested free port.
```

### Start on the Jetson

Run this each time you want to start the desktop:

```bash
cd ~/vnc-ros
./scripts/start-jetson-novnc-system.sh
```

Keep this terminal open. When you see output like this, the Jetson side is running:

```text
noVNC is listening on port 31880
Secure mode is enabled. Use SSH tunnel, then open http://localhost:31880/vnc.html
Press Ctrl+C here to stop it.
```

Do not open the Jetson's printed `localhost:31880` directly from your local browser. That address is local to the Jetson. Open an SSH tunnel from the local computer first.

### Connect from the Local Computer

Open a new terminal on the local computer:

```bash
ssh -N -L 18080:127.0.0.1:<NOVNC_PORT> <jetson-user>@<jetson-ip>
```

Example:

```bash
ssh -N -L 18080:127.0.0.1:31880 wheeltec@192.168.124.162
```

After entering the Jetson password, the terminal will stay open. That is expected. Do not close it.

Then open this in a browser:

```text
http://localhost:18080/vnc.html
```

Click **Connect** to enter the Jetson graphical desktop.

### Use the Browser Desktop

The terminal inside the browser desktop runs on the Jetson. You can run:

```bash
ros2 topic list
ros2 node list
rviz2
rqt
rqt_graph
rqt_image_view
```

GUI applications launched from that terminal appear inside the browser noVNC desktop.

### Port Reference

SSH tunnel format:

```bash
ssh -N -L local-port:127.0.0.1:jetson-port user@jetson-ip
```

Example:

```bash
ssh -N -L 18080:127.0.0.1:31880 wheeltec@192.168.124.162
```

Meaning:

```text
18080:
  Local computer port. Open localhost:18080 in the browser.
  If occupied, change it to another port such as 18081 or 28080.

31880:
  Jetson noVNC port. This is the NOVNC_PORT value written to .env by setup.
```

If local port `18080` is occupied:

```bash
ssh -N -L 18081:127.0.0.1:31880 wheeltec@192.168.124.162
```

Then open:

```text
http://localhost:18081/vnc.html
```

### Change Configuration

Edit `.env` on the Jetson:

```bash
cd ~/vnc-ros
nano .env
```

Common settings:

```bash
ROS_DOMAIN_ID=7
JETSON_ROS_SETUP=/home/wheeltec/wheeltec_ros2/install/setup.bash
NOVNC_LISTEN_HOST=127.0.0.1
NOVNC_PORT=31880
VNC_PORT=31901
```

Restart after changing `.env`:

```bash
./scripts/start-jetson-novnc-system.sh
```

### Direct LAN Access

Direct LAN access is disabled by default. If you intentionally want other machines on the same LAN to open the Jetson URL directly, set this in `.env` on the Jetson:

```bash
NOVNC_LISTEN_HOST=0.0.0.0
```

Restart the service, then open:

```text
http://<jetson-ip>:<NOVNC_PORT>/vnc.html
```

Warning: anyone on the trusted LAN who knows the address and port may be able to access the desktop.

### Stop the Service

Press this in the Jetson terminal running `start-jetson-novnc-system.sh`:

```text
Ctrl+C
```

If ports remain occupied after an abnormal exit:

```bash
pkill -f websockify || true
pkill -f x11vnc || true
pkill -f Xvfb || true
```

### Troubleshooting

If the noVNC page does not open:

```bash
cd ~/vnc-ros
ss -lntp | grep -E ':31880|:31901|:5900' || true
tail -n 80 logs/novnc.log logs/x11vnc.log logs/xvfb.log
```

If the page opens but **Connect** fails, the backend VNC port is often occupied. Change `VNC_PORT` in `.env` and restart.

If `rviz2` cannot see robot topics:

- verify `ROS_DOMAIN_ID`
- verify `JETSON_ROS_SETUP`
- run `ros2 topic list` inside the browser terminal

If `ssh -L` reports `Address already in use`:

- change the local port, for example from `18080` to `18081`
- open the matching browser URL, such as `http://localhost:18081/vnc.html`

### Additional Documents

- [QUICKSTART.md](QUICKSTART.md): shortest usage flow
- [LOCAL_TUNNEL.md](LOCAL_TUNNEL.md): SSH tunnel instructions for Mac, Linux, and Windows
- [JETSON_NOVNC.md](JETSON_NOVNC.md): Jetson noVNC details
- [DISTRIBUTING_JETSON_NOVNC.md](DISTRIBUTING_JETSON_NOVNC.md): notes for sharing this project with other users
