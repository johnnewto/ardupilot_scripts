#!/bin/bash

# Kill any existing sim_vehicle processes
pkill -f sim_vehicle.py

# Start the simulation with Orakei, Auckland home position

# sim_vehicle.py -v Rover -f motorboat -A "--serial2=uart:/dev/ttyUSB3:9600" --console --map -L Orakei_Bay --aircraft Boat --speedup 1 
# sim_vehicle.py -v Rover -f motorboat -A "--serial2=logic_async_csv:victron_mppt_5min.csv:9600" --console --map -L Orakei_Bay  --speedup 1 

sim_vehicle.py -v Rover -f motorboat -A "--serial2=uart:/dev/ttyUSB1" --console --map -L Orakei_Bay --aircraft Boat 
# sim_vehicle.py -v Rover -f motorboat -A "--serial2=uart:/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_A50285BI-if00-port0" --console --map -L Orakei_Bay --aircraft Boat --speedup 1 

