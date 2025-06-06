#!/usr/bin/env python3
from vedirect import Vedirect
import serial
import time

# Configuration
PORT = '/dev/ttyUSB1'
BAUDRATE = 19200  # Default baud rate for VE.Direct protocol
TIMEOUT = 1       # Timeout in seconds for serial communication

def read_victron_data_loop():
    try:
        ser = serial.Serial(PORT, BAUDRATE, timeout=TIMEOUT)
        print("Reading Victron data. Press Ctrl+C to exit.")
        while True:
            data = {}
            start_time = time.time()
            # Read for a short period to capture a full set of fields
            while time.time() - start_time < 2:
                line = ser.readline().decode('ascii', errors='ignore').strip()
                if line:
                    try:
                        key, value = line.split('\t')
                        data[key] = value
                    except ValueError:
                        continue
            # Extract and convert relevant fields
            solar_power = float(data.get('PPV', 0))  # Panel power in watts
            solar_voltage = float(data.get('VPV', 0)) / 1000  # Panel voltage in mV, convert to V
            battery_voltage = float(data.get('V', 0)) / 1000   # Battery voltage in mV, convert to V
            battery_current = float(data.get('I', 0)) / 1000   # Battery current in mA, convert to A

            time.sleep(1)
    except serial.SerialException as e:
        print(f"Error opening serial port: {e}")
    except KeyboardInterrupt:
        print("\nExiting on user request.")
    except Exception as e:
        print(f"Error processing data: {e}")
    finally:
        try:
            ser.close()
        except:
            pass

if __name__ == "__main__":
    read_victron_data_loop()