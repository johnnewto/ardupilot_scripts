# VE.Direct Protocol

## Theory

The VE.Direct protocol is a communication interface developed by Victron Energy, primarily for their energy monitoring products. This protocol is designed for real-time data exchange between devices like Battery Management Systems (BMS), solar charge controllers, and various monitoring devices. VE.Direct uses a simple serial connection with a standard UART interface, enabling data transfer at a low baud rate (commonly 19,200 bps). This protocol is especially useful for monitoring device metrics, such as voltage, current, and battery capacity, which can be helpful for energy management and control.

Data in VE.Direct is mainly transmitted as ASCII text in a predefined message format, making it easy to parse and interpret. During setup of a new connected device, there might be also hex strings transmitted. The protocol's simplicity is a double-edged sword: while it's efficient for quick data retrieval, the lack of encryption or authentication makes it susceptible to interception or manipulation if physical access is available. This feature is crucial for pentesters as it opens the door for potential vulnerabilities, especially if critical devices rely on VE.Direct for automated decision-making processes.

## Serial Configuration

| Parameter | Value |
|-----------|-------|
| Baud rate | 19200 |
| Data bits | 8 |
| Parity | None |
| Stop bits | 1 |
| Flow control | None |

## Protocol Fields

VE.Direct has a number of possible fields. Here are some common fields and their descriptions:

| Field | Example Value | Description |
|-------|---------------|-------------|
| PID | 0xA053 | Product ID of the device, used to identify the specific model and type of device |
| FW | 137 | Firmware version, useful for knowing the device's software version |
| SER# | XXXXXX | Serial number of the device, typically unique to each device |
| V | 11680 | Battery voltage in millivolts (mV). Here, 11680 mV equals 11.68 V |
| I | 0 | Battery current in milliamperes (mA). Positive values mean charging, negative indicate discharge |
| VPV | 10 | Panel voltage in mV. Shows the voltage from connected solar panels |
| PPV | 0 | Panel power in watts (W), calculated as voltage times current of the panels |
| CS | 0 | Charge state indicator, where 0 means "Off" and higher values indicate other charging states |
| MPPT | 0 | Maximum Power Point Tracking (MPPT) mode; 0 means disabled |
| ERR | 0 | Error code; 0 indicates no error. Different values represent various error states |
| LOAD | ON | Load output status; "ON" means the load output is active |
| IL | 0 | Load current in mA, showing the current drawn by the load |
| H19 | 83 | Yield total in kilowatt-hours (kWh), representing the total energy yield since installation |
| H20 | 83 | Yield today in kWh, showing energy produced in the current day |
| H21 | 0 | Maximum power today in W, showing peak power achieved |
| H22 | 0 | Maximum power yesterday in W, showing peak power from the previous day |
| H23 | 0 | Yield yesterday in kWh, showing energy produced the previous day |
| HSDS | 0 | Day sequence number; increments daily and helps track historical data over time |

## Checksum

The checksum is correct if the sum of the whole message (including the checksum) equals 0 modulo 256.

## Protocol Analysis

### Sniffing VE.Direct Data

To capture VE.Direct protocol data, you can use either:
- UART-to-TTL USB adapter
- Saleae Logic Analyzer

#### Connection Setup
Connect the following pins to your adapter:
- RX (Receive)
- TX (Transmit)
- GND (Ground)

#### Using Terminal Tools

1. Using minicom:
```bash
sudo minicom -D /dev/ttyUSB1 -b 19200
```

2. Using picocom:
```bash
sudo picocom -b 19200 -r -l /dev/ttyUSB1
```

#### Example Output
```
PID     0xA053
FW      137
SER#    XXXXXX
V       11680
I       0
VPV     10
PPV     0
CS      0
MPPT    0
ERR     0
LOAD    ON
IL      0
H19     83
H20     83
H21     0
H22     0
H23     0
HSDS    0
Checksum        \xF0
```

### Spoofing VE.Direct Messages

Since the VE.Direct protocol does not implement authentication, it's possible to:
1. Record original messages
2. Replay recorded messages
3. Modify message parameters

Note: When modifying messages, the checksum must be recalculated to maintain protocol compliance.

## Resources

- [VE.Direct Protocol Documentation (PDF)](https://www.victronenergy.com/upload/documents/VE.Direct-Protocol-3.33.pdf)
- [Python VE.Direct Protocol Library](https://github.com/karioja/vedirect)
