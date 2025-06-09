'''
This script is used to get the history of the solar system.
It will get the history of the last 10 days.
It will also print the data to the console.

'''


import serial
import time
from datetime import datetime, timedelta

# Serial port configuration (adjust port based on your setup, e.g., 'COM3' on Windows, '/dev/ttyUSB0' on Linux)
PORT = '/dev/ttyUSB1'  # Change to your VE.Direct port
BAUDRATE = 19200  # VE.Direct standard baud rate
TIMEOUT = 1  # Seconds to wait for response

# Function to calculate VE.Direct HEX checksum
#  ie 0x55-0x08-0xF0-0xED-0x00-0x64-0x00 = 0x0C
def calculate_checksum(message):
    checksum = 0x55  # Initial value per VE.Direct protocol
    for byte in message:
        print('byte: ', hex(byte))
        checksum -= byte
    checksum = checksum & 0xFF  # Ensure 8-bit result
    # print('checksum: ', hex(checksum))
    return bytes([checksum])  # Return as single byte

def bytes_to_hex_string(byte_data):
    # Convert bytes to hex string, removing '0x' prefix and joining
    return ''.join([f'{b:02X}' for b in byte_data])

def hex_to_bytes(hex_string):
    return bytes.fromhex(hex_string)


# Open serial connection
try:
    ser = serial.Serial(PORT, BAUDRATE, timeout=TIMEOUT)
    print(f"Connected to {PORT}")
except Exception as e:
    print(f"Error opening serial port: {e}")
    exit(1)


# Loop through 30 days of history (0 = today, 1 = yesterday, etc.)
for day in range(10):
    # Build HEX command for history day record (registers 0x1050..0x106E)
    # 7 = get 

    base_command = '7'+ str(50+day) + '10'+'00'

    checksum = calculate_checksum(bytes.fromhex('0'+base_command))
    checksum_hex = bytes_to_hex_string(checksum)
    # Construct command with hex string representation
    command = str.encode(':' + base_command + checksum_hex + '\n')
    print('command:', command, ' Should show:',  "b':7501000EE\\n'")
    
    (WAIT_HEADER, WAIT_CR, FOUND) = range(3)
    # Send command
    try:
        ser.write(command)
        time.sleep(0.1)  # Wait for response

        # read in a loop till ':7A8ED' is found
        found = False
        buffer = b''
        state = WAIT_HEADER
        while state != FOUND or len(buffer) < 80:
            char = ser.read(1)
            if char:
                buffer += char
                # Check if buffer ends with our target string
                if state == WAIT_HEADER:
                    if buffer.endswith(base_command.encode()):
                        state = WAIT_CR
                        print('buffer:', buffer)
                        buffer = b''
                elif state == WAIT_CR:
                    if  buffer.endswith(b'\n'):
                        state = FOUND
                        print('buffer:', buffer)
                        #  convert to string
                        response = buffer[64:68].decode('utf-8')
                        # convert to hex
                        response = bytes.fromhex(response)
                        day_sequence = int.from_bytes(response, 'little')  # Day sequence number
                        print('day_sequence:', day_sequence)

    except Exception as e:
        print(f"Error for day {day}: {e}")

