# ros2-novnc-desktop | Ubuntu / ROS 2 noVNC 远程桌面（无需 X11 转发）

<p align="left">
  <a href="README.md"><img src="https://img.shields.io/badge/切换语言-简体中文-blue" alt="简体中文"></a>
  <a href="README.en.md"><img src="https://img.shields.io/badge/Switch-English-blue" alt="English"></a>
</p>

`ros2-novnc-desktop` 可以让用户在 **macOS、Windows、Linux** 的浏览器里查看和操作远程 Ubuntu / ROS 2 设备上的图形工具，例如 `rviz2`、`rqt`、`rqt_graph`、`rqt_image_view` 和图形终端。

图形程序实际运行在远程 Ubuntu / ROS 2 设备上，本地电脑只接收 noVNC 网页画面。整个流程无需 SSH X11 转发，因此可以避开 X11 转发在 Apple Silicon Mac 或跨平台环境里的卡顿问题；本地电脑也不需要安装 ROS 2、RViz、rqt、Docker、XQuartz 或 VNC 客户端。

![noVNC 连接页面](docs/images/novnc-connect.png)

![浏览器中的 RViz2](docs/images/rviz2-browser.png)

## 适合解决什么问题

- 在 Mac Apple Silicon、Windows 或 Linux 电脑上通过浏览器查看远程 Ubuntu / ROS 2 设备的 RViz2、rqt 等图形界面，无需 X11 转发。
- 让使用者无需配置本地 ROS 环境，也能快速查看机器人状态、topic、tf、地图、点云等。
- 通过 SSH 隧道访问 noVNC，默认不把远程设备的 noVNC 端口暴露给局域网。

## 工作方式

远程 Ubuntu / ROS 2 设备上启动一个轻量虚拟桌面：

- `Xvfb` 提供虚拟显示器
- `fluxbox` 提供窗口管理器
- `x11vnc` 把虚拟桌面变成 VNC
- `websockify` / noVNC 把 VNC 变成浏览器页面
- `rviz2`、`rqt` 等程序在远程设备本机运行

默认安全模式下，noVNC 只监听远程设备的 `127.0.0.1`。本地电脑通过 SSH 隧道访问：

```text
本地浏览器 -> localhost:18080 -> SSH 隧道 -> 远程设备 127.0.0.1:<NOVNC_PORT>
```

## 远程设备要求

- Ubuntu，并已安装 ROS 2，通常是 Ubuntu 22.04 + ROS 2 Humble
- 已开启 SSH
- 当前用户可以执行 `sudo apt-get`
- 如果机器人有自定义消息或 launch 文件，需要知道工作区的 `install/setup.bash` 绝对路径

## 本地电脑要求

macOS / Linux / Windows 均可使用。

本地电脑只需要：

- 浏览器
- `ssh` 命令
- 能通过网络访问远程 Ubuntu / ROS 2 设备

Windows 用户可以使用 PowerShell 或 Windows Terminal。若系统没有 `ssh`，需要启用 OpenSSH Client。

## 快速上手

### 1. 远程设备第一次安装配置

在远程 Ubuntu / ROS 2 设备上运行：

```bash
git clone -b ros2-humble https://github.com/<your-github-user>/ros2-novnc-desktop.git
cd ros2-novnc-desktop
./scripts/setup-ros2-novnc-system.sh
```

安装脚本会自动：

- 创建 `.env`
- 询问 `ROS_DOMAIN_ID`
- 询问机器人工作区 setup 文件路径，例如 `/home/<user>/<robot_ws>/install/setup.bash`
- 自动推荐不常见且未占用的端口，通常从 `31880` 和 `31901` 开始找
- 检查端口是否有效、是否被占用、两个端口是否冲突
- 安装 noVNC、Xvfb、x11vnc、fluxbox、xterm 等依赖
- 最后输出本地电脑需要执行的 SSH 隧道命令

提示项说明：

```text
ROS_DOMAIN_ID:
  填机器人 ROS 2 使用的 domain id。不确定时先用 0。

Absolute robot workspace setup file:
  如果机器人工作区需要 source，填写绝对路径。
  例如 /home/<user>/<robot_ws>/install/setup.bash
  不需要则直接回车。

noVNC web port:
  远程设备上的 noVNC 网页端口。建议直接回车使用推荐值。

Internal VNC backend port:
  远程设备内部 VNC 后端端口。建议直接回车使用推荐值。
```

### 2. 远程设备每次启动

```bash
cd ~/ros2-novnc-desktop
./scripts/start-ros2-novnc-system.sh
```

保持这个终端不要关闭。看到类似输出后说明远程设备端已启动：

```text
noVNC is listening on port 31880
Secure mode is enabled. Use SSH tunnel, then open http://localhost:31880/vnc.html
Press Ctrl+C here to stop it.
```

注意：这里的 `localhost:31880` 是远程设备自己的本地地址，不是你本地电脑的浏览器地址。本地电脑需要先开 SSH 隧道。

### 3. 本地电脑打开 SSH 隧道

在 macOS、Linux 或 Windows PowerShell 中运行：

```bash
ssh -N -L 18080:127.0.0.1:<NOVNC_PORT> <device-user>@<device-host>
```

如果 setup 脚本输出的 `NOVNC_PORT` 是 `31880`，命令类似：

```bash
ssh -N -L 18080:127.0.0.1:31880 <device-user>@<device-host>
```

输入远程设备用户密码后，终端停住是正常的。保持这个终端不要关闭。

也可以使用项目自带脚本打开隧道：

```bash
./scripts/open-ros2-novnc-tunnel.sh <device-user>@<device-host>
```

### 4. 浏览器访问

打开：

```text
http://localhost:18080/vnc.html
```

点击 **Connect** 后即可进入远程 ROS 2 图形桌面。

## 常用命令

在网页桌面的终端里运行：

```bash
ros2 topic list
ros2 node list
rviz2
rqt
rqt_graph
rqt_image_view
```

这些命令都在远程设备上执行，图形窗口会显示在浏览器 noVNC 桌面里。

## 端口说明

SSH 隧道格式：

```bash
ssh -N -L 本地端口:127.0.0.1:远程设备端口 用户名@设备地址
```

例如：

```bash
ssh -N -L 18080:127.0.0.1:31880 <device-user>@<device-host>
```

- `18080` 是本地电脑端口，浏览器打开 `localhost:18080`。
- `31880` 是远程设备 noVNC 端口，由 setup 脚本写入 `.env` 的 `NOVNC_PORT`。
- 两个端口都不是固定值。如果本地 `18080` 被占用，可以换成 `18081`。

本地端口换成 `18081` 的例子：

```bash
ssh -N -L 18081:127.0.0.1:31880 <device-user>@<device-host>
```

浏览器打开：

```text
http://localhost:18081/vnc.html
```

## 修改配置

在远程设备上编辑 `.env`：

```bash
cd ~/ros2-novnc-desktop
nano .env
```

常见配置：

```bash
ROS_DOMAIN_ID=7
ROS_SETUP=/home/<user>/<robot_ws>/install/setup.bash
NOVNC_LISTEN_HOST=127.0.0.1
NOVNC_PORT=31880
VNC_PORT=31901
```

修改后重启：

```bash
./scripts/start-ros2-novnc-system.sh
```

## 直接局域网访问

默认不建议直接暴露 noVNC 到局域网。如果确实需要同一局域网用户直接打开远程设备地址，可以在 `.env` 中设置：

```bash
NOVNC_LISTEN_HOST=0.0.0.0
```

然后重启服务，浏览器打开：

```text
http://<device-host>:<NOVNC_PORT>/vnc.html
```

注意：这样同一局域网中知道地址和端口的人都可能打开桌面。只在可信网络中使用。

## 停止服务

在运行 `start-ros2-novnc-system.sh` 的远程设备终端按：

```text
Ctrl+C
```

如果异常退出后端口仍被占用：

```bash
pkill -f websockify || true
pkill -f x11vnc || true
pkill -f Xvfb || true
```

## 常见问题

页面打不开：

```bash
cd ~/ros2-novnc-desktop
ss -lntp | grep -E ':31880|:31901|:5900' || true
tail -n 80 logs/novnc.log logs/x11vnc.log logs/xvfb.log
```

页面能打开但点击 Connect 失败：

- 通常是后端 VNC 端口冲突
- 修改 `.env` 里的 `VNC_PORT`
- 重启 `./scripts/start-ros2-novnc-system.sh`

`rviz2` 看不到机器人 topic：

- 检查 `ROS_DOMAIN_ID` 是否和机器人一致
- 检查 `ROS_SETUP` 是否指向正确工作区
- 在网页终端里运行 `ros2 topic list`

本地 `ssh -L` 提示 `Address already in use`：

- 换一个本地端口，例如从 `18080` 改成 `18081`
- 浏览器也对应打开 `http://localhost:18081/vnc.html`

## 相关文档

- [QUICKSTART.md](QUICKSTART.md)
- [LOCAL_TUNNEL.md](LOCAL_TUNNEL.md)
