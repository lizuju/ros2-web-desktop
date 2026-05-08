# ROS 2 Development Environment (Mac & Windows)

This repository provides a containerized **ROS 2 Humble** environment with a virtual desktop (NoVNC) accessible via your web browser. This setup allows you to run GUI-based robotics tools like Gazebo and Rviz without needing a native Linux installation.

For viewing a remote Jetson's `rviz2` / `rqt` from a Mac, Linux, or Windows computer without SSH X11 forwarding, use the Jetson noVNC mode in [JETSON_NOVNC.md](JETSON_NOVNC.md). The secure default uses a local SSH tunnel documented in [LOCAL_TUNNEL.md](LOCAL_TUNNEL.md).

## Prerequisites

Before following the instructions below, you must install **Docker Desktop**:
* [Download for Mac](https://docs.docker.com/desktop/install/mac-install/)
* [Download for Windows](https://docs.docker.com/desktop/install/windows-install/) (Ensure the **WSL 2 backend** is enabled in settings).

---

## 1. Setup

Open a **Terminal** (Mac) or **PowerShell** (Windows) and follow these steps in order:

### A. Clone the Repository
```bash
git clone https://github.com/quattrinili/vnc-ros
cd vnc-ros
```

### B. Ensure Local Workspace Exists
The local `ros2_ws/src` folder is shared with the Docker container at `/root/ros2_ws/src` and is where you will write and edit your ROS packages.

If `ros2_ws/src` is already in the repository, you can skip this step.
If it is missing, create it with:
```bash
mkdir -p ros2_ws/src
```

### C. Launch the Containers
```bash
docker compose up
```
*(Note: `ros.env` contains environment variables for ROS that can be modified before running this command.)*

---

## 2. Running a ROS Gazebo Simulation

Once the terminal shows the following type of messages and remains running without errors:
`vnc-ros-novnc-1 | ... INFO success: xterm entered RUNNING state`

### A. Access the Visual Desktop
1. Open your web browser and navigate to: [http://localhost:8080/vnc.html](http://localhost:8080/vnc.html)
2. Click **Connect**. You should see a Linux desktop environment.

### B. Launch the Simulation
Open a **new (second) terminal window** on your host machine and run:
1. **Enter the ROS container:**
   ```bash
   cd vnc-ros
   docker compose exec ros bash
   ```
2. **Load the ROS environment:**
   ```bash
   source /opt/ros/humble/setup.bash
   ```
   *(This is already added in `.bashrc`, but we run it explicitly for clarity and reliability.)*
3. **Launch the world:**
   ```bash
   ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py
   ```
   *You can now see the robot in the web page opened in Step A.*

### C. Teleoperate the Robot
Open a **third terminal window** on your host machine and run:
1. **Enter the ROS container:**
   ```bash
   cd vnc-ros
   docker compose exec ros bash
   ```
2. **Load the ROS environment:**
   ```bash
   source /opt/ros/humble/setup.bash
   ```
3. **Run the teleop node:**
   ```bash
   ros2 run teleop_twist_keyboard teleop_twist_keyboard
   ```
   *Follow the on-screen instructions to drive the robot using your keyboard. Watch the robot move in your browser window.*

---

## 3. Termination

To properly stop the environment and clean up:

1. In the **Simulation** and **Teleop** terminals: Press `Ctrl+C` to stop the active nodes, then type `exit` (or press `Ctrl+D`) to leave the container.
2. In the **original terminal** (where `docker compose up` is running): Press `Ctrl+C`. You should see output indicating the containers are stopping:
   ```text
   Stopping vnc-ros-ros-1   ... done
   Stopping vnc-ros-novnc-1 ... done
   ```
3. Once terminated, all terminal windows can be closed.

---

## Development Notes

### Editing your Workspace
The `ros2_ws/src` folder on your machine is dynamically mapped to `/root/ros2_ws/src` inside the Docker container. You can use your favorite IDE (e.g., VS Code) on your host machine to edit your packages within this folder.

### Installing Additional Packages
To add new dependencies to the environment:
1. Edit the `Dockerfile` line that installs packages (`apt-get install`).
2. Rebuild the container using the following command before running `docker compose up`:
   ```bash
   docker compose build
   ```
