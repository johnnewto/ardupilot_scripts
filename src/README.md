# Python Scripts for ArduPilot

This directory contains Python scripts for testing and protyping with ArduPilot related hardware.

## Directory Structure
```
src/
├── README.md
├── vedirect_print.py
└── ve_direct_history.py
```

## Available Scripts

### `vedirect_print.py`

A Python script for reading and displaying VE.Direct protocol data from Victron Energy devices.

#### Features
- Reads VE.Direct protocol data at 19200 baud rate
- Parses solar and battery data
- Formats and displays values with proper units
- Supports both single reading and callback modes

#### Usage
```bash
python3 vedirect_print.py
```

#### Output Format
```
Solar Power: XX.XX W, Solar Voltage: XX.XX V, Solar Current: XX.XX A, Battery Voltage: XX.XX V, Battery Current: XX.XX A
```

#### Data Fields
- Solar Power (PPV): Power in Watts
- Solar Voltage (VPV): Voltage in Volts (converted from mV)
- Solar Current: Calculated from power and voltage
- Battery Voltage (V): Voltage in Volts (converted from mV)
- Battery Current (I): Current in Amperes (converted from mA)

#### Configuration
- Default port: `/dev/ttyUSB1`
- Baud rate: 19200
- Timeout: 1 second

#### Dependencies
- Python 3.x
- pyserial
- vedirect module

### `ve_direct_history.py`

A Python script for retrieving and storing historical data from Victron Energy devices using the VE.Direct protocol.

#### Features
- Retrieves historical data for the last 10 days
- Parses detailed daily statistics including power, voltage, and error records
- Saves data to CSV format for easy analysis
- Supports VE.Direct protocol checksum verification

#### Usage
```bash
python3 ve_direct_history.py
```

#### Output Format
The script generates a CSV file (`solar_history.csv`) with the following columns:
- Day (0 = today, 1 = yesterday, etc.)
- Estimated Date
- Total Yield (kWh)
- Max Power Today (W)
- Max PV Voltage Today (V)
- Max Battery Voltage Today (V)
- Min Battery Voltage Today (V)
- Day Sequence
- Time in Bulk (min)
- Time in Absorption (min)
- Time in Float (min)
- Max Battery Current (A)
- Error Codes (4 most recent)
- Consumed Energy (kWh)

#### Configuration
- Default port: `/dev/ttyUSB1`
- Baud rate: 19200
- Timeout: 1 second
- History depth: 10 days

#### Dependencies
- Python 3.x
- pyserial

## Installation

1. Create and activate a virtual environment:
```bash
python3 -m venv venv
source venv-ardupilot/bin/activate
```

2. Install required packages:
```bash
pip install pyserial
```

## Development

### Adding New Scripts
1. Create new Python script in this directory
2. Add proper documentation
3. Update this README with new script information

### Testing
- Test scripts with actual hardware when possible
- Verify unit conversions and calculations
- Check error handling and edge cases

## Notes
- Some scripts may require specific hardware connections
- Always verify port configurations before running scripts 