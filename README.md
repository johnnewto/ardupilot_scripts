# ardupilot_scripts
ardupilot scripts for sea drone

## Repository Structure

The repository contains a `scripts` directory that is symlinked to the ArduPilot repository. This allows the scripts to be used directly within the ArduPilot environment.

### Setting up the Symlink

To create the symlink between this repository and ArduPilot:

```bash
ln -s ~/repos/ardupilot_scripts/scripts ~/repos/ardupilot/scripts
```

This creates a symbolic link that makes the scripts in this repository available to ArduPilot while maintaining the ability to version control them separately.

### Available Scripts

The `scripts` directory contains:

- `position_report.lua`: A Lua script for reporting vehicle position data. This script is used within the ArduPilot environment to track and report the position of the sea drone.

## Setting up SITL

Before running the simulation, you need to set up the Software In The Loop (SITL) environment. Please follow the official ArduPilot documentation for setting up SITL on Linux:

[Setting up SITL on Linux](https://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html)

This guide will walk you through:
- Installing required dependencies
- Setting up the build environment
- Configuring SITL for your system

## Running SITL Simulation

The repository includes a `run_sim.sh` script to launch ArduPilot's Software In The Loop (SITL) simulation for a motorboat vehicle.

### Prerequisites
- ArduPilot installed and configured
- Python environment with required dependencies
- SITL simulation files (including eeprom.bin)

### Running the Simulation

1. Make the script executable:
```bash
chmod +x run_sim.sh
```

2. Run the simulation:
```bash
./run_sim.sh
```

The script will:
- Kill any existing sim_vehicle processes
- Launch a new SITL simulation with the following configuration:
  - Vehicle type: Rover
  - Frame: motorboat
  - Location: Orakei Bay
  - Speedup: 1x
  - Serial2 interface: UART on /dev/ttyUSB1
  - Console and map interfaces enabled

3. Arm

To arm or disarm the vehicle in SITL using MAVProxy, use the following commands in the MAVProxy console:

- To arm:
  ```
  arm throttle
  ```
- To force arm (bypass checks):
  ```
  arm throttle force
  ```
- To disarm:
  ```
  disarm
  ```

![MAVProxy Arming Interface](images/Screenshot%20from%202025-06-04%2019-39-56.png)

For more details and advanced options (such as enabling/disabling specific arming checks), see the official ArduPilot documentation: [Arming and Disarming with MAVProxy](https://ardupilot.org/mavproxy/docs/uav_configuration/arming.html)

### Simulation Files

The SITL simulation uses several files in the simulation directory:
- `eeprom.bin`: Stores simulated vehicle parameters
- `motorboat.parm`: Vehicle-specific parameters
- Other configuration files as needed

### Alternative Configurations

The script includes commented-out alternative configurations for:
- Different serial interfaces
- CSV-based simulation
- Different USB device paths

To use an alternative configuration, uncomment the desired line and comment out the current active configuration.