'''
This script is used to get the history of the solar system.
It will get the history of the last 10 days.
It will save the data to a CSV file.
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
    print('checksum: ', hex(checksum))
    return bytes([checksum])  # Return as single byte

def bytes_to_hex_string(byte_data):
    # Convert bytes to hex string, removing '0x' prefix and joining
    return ''.join([f'{b:02X}' for b in byte_data])

def hex_to_bytes(hex_string):
    return bytes.fromhex(hex_string)

# Function to parse the HEX response (34-byte payload for history day record)
def parse_history_record(response):
    if len(response) < 34:  # Check if payload is too short
        print("Error: Incomplete response")
        return None
    try:
        #  convert to string
        response = response.decode('utf-8')
        # convert to hex
        response = bytes.fromhex(response)

        # Extract fields from 34-byte payload according to the correct order
        reserved = int.from_bytes(response[0:1], 'little')  # Should be 0
        yield_total = int.from_bytes(response[1:5], 'little') / 100.0  # kWh, scaled by 0.01
        consumed = int.from_bytes(response[5:9], 'little') / 100.0  # kWh, scaled by 0.01
        max_bat_voltage = int.from_bytes(response[9:11], 'little') / 100.0  # V, scaled by 0.01
        min_bat_voltage = int.from_bytes(response[11:13], 'little') / 100.0  # V, scaled by 0.01
        error_db = int.from_bytes(response[13:14], 'little')  # Should be 0
        error_0 = int.from_bytes(response[14:15], 'little')  # Most recent error
        error_1 = int.from_bytes(response[15:16], 'little')
        error_2 = int.from_bytes(response[16:17], 'little')
        error_3 = int.from_bytes(response[17:18], 'little')  # Oldest error
        time_bulk = int.from_bytes(response[18:20], 'little')  # Minutes
        time_absorption = int.from_bytes(response[20:22], 'little')  # Minutes
        time_float = int.from_bytes(response[22:24], 'little')  # Minutes
        max_power = int.from_bytes(response[24:28], 'little')  # W
        max_bat_current = int.from_bytes(response[28:30], 'little') / 10.0  # A, scaled by 0.1
        max_pv_voltage = int.from_bytes(response[30:32], 'little') / 100.0  # V, scaled by 0.01
        day_sequence = int.from_bytes(response[32:34], 'little')  # Day sequence number

        return {
            'Reserved': reserved,
            'Total Yield (kWh)': yield_total,
            'Consumed (kWh)': consumed,
            'Max Battery Voltage (V)': max_bat_voltage,
            'Min Battery Voltage (V)': min_bat_voltage,
            'Error Database': error_db,
            'Error 0 (Most Recent)': error_0,
            'Error 1': error_1,
            'Error 2': error_2,
            'Error 3 (Oldest)': error_3,
            'Time in Bulk (min)': time_bulk,
            'Time in Absorption (min)': time_absorption,
            'Time in Float (min)': time_float,
            'Max Power (W)': max_power,
            'Max Battery Current (A)': max_bat_current,
            'Max PV Voltage (V)': max_pv_voltage,
            'Day Sequence': day_sequence
        }
    except Exception as e:
        print(f"Error parsing response: {e}")
        return None

# Open serial connection
try:
    ser = serial.Serial(PORT, BAUDRATE, timeout=TIMEOUT)
    print(f"Connected to {PORT}")
except Exception as e:
    print(f"Error opening serial port: {e}")
    exit(1)

# CSV file setup
csv_file = 'solar_history.csv'
f = open(csv_file, 'w')
# Write CSV header
f.write("Day,Estimated Date,Total Yield (kWh),Max Power Today (W),Max PV Voltage Today (V),"
        "Max Battery Voltage Today (V),Min Battery Voltage Today (V),Day Sequence,"
        "Time in Bulk (min),Time in Absorption (min),Time in Float (min),"
        "Max Battery Current (A),Error Code 1,Error Code 2,Error Code 3,Error Code 4,"
        "Yield Yesterday (kWh)\n")
    

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
                        parsed_data = parse_history_record(buffer)
                        print('parsed_data:', parsed_data)
                        
                        if parsed_data:
                            # Calculate estimated date (days ago from today)
                            estimated_date = (datetime.now() - timedelta(days=day)).strftime('%Y-%m-%d')
                            
                            # Write data to CSV
                            f.write(f"{day},{estimated_date},"
                                   f"{parsed_data['Total Yield (kWh)']},"
                                   f"{parsed_data['Max Power (W)']},"
                                   f"{parsed_data['Max PV Voltage (V)']},"
                                   f"{parsed_data['Max Battery Voltage (V)']},"
                                   f"{parsed_data['Min Battery Voltage (V)']},"
                                   f"{parsed_data['Day Sequence']},"
                                   f"{parsed_data['Time in Bulk (min)']},"
                                   f"{parsed_data['Time in Absorption (min)']},"
                                   f"{parsed_data['Time in Float (min)']},"
                                   f"{parsed_data['Max Battery Current (A)']},"
                                   f"{parsed_data['Error 0 (Most Recent)']},"
                                   f"{parsed_data['Error 1']},"
                                   f"{parsed_data['Error 2']},"
                                   f"{parsed_data['Error 3 (Oldest)']},"
                                   f"{parsed_data['Consumed (kWh)']},"
                                   f"{parsed_data['Day Sequence']}\n"
                                   )
                            
                            
                                    
                    # ... existing code ...
    except Exception as e:
        print(f"Error for day {day}: {e}")

# Close serial connection
ser.close()
f.close()
print(f"Data saved to {csv_file}")