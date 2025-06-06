#!/usr/bin/python3
# -*- coding: utf-8 -*-

import argparse, os
from vedirect import Vedirect
# Configuration
PORT = '/dev/ttyUSB1'
BAUDRATE = 19200  # Default baud rate for VE.Direct protocol
TIMEOUT = 1       # Timeout in seconds for serial communication

def print_data_callback(packet):
    print(packet)

if __name__ == '__main__':
    ve = Vedirect(PORT, TIMEOUT)
    # print(ve.read_data_callback(print_data_callback))
    packet = ve.read_data_single()
    
    # Extract values from packet, defaulting to 0 if not present
    solar_power = float(packet.get('PPV', 0))  #  W
    solar_voltage = float(packet.get('VPV', 0)) / 1000.0  # Convert from 0.001V to V
    solar_current = float(packet.get('PPV', 0)) / solar_voltage  # Convert from 0.1W to W
    battery_voltage = float(packet.get('V', 0)) / 1000.0  # Convert from 0.001V to V
    battery_current = float(packet.get('I', 0)) / 1000.0  # Convert from 0.001A to A
    
    print("Solar Power: %.2f W, Solar Voltage: %.2f V, Solar Current: %.2f A, Battery Voltage: %.2f V, Battery Current: %.2f A" % 
          (solar_power, solar_voltage, solar_current, battery_voltage, battery_current))

    
