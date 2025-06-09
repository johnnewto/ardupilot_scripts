'''
This script is used to get the history of the solar system.
It will get the history of the last 10 days.
It will also print the data to the console.

'''

import serial
import time
from datetime import datetime, timedelta

class SolarHistory:
    def __init__(self, port, baudrate=19200, timeout=1):
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.ser = None
        self.buffer = b''
        self.base_command = ''
        self.day_sequence = None
        
        # States
        (GET_DAY, WAIT_HEADER, WAIT_CR, FOUND) = range(4)
        self.GET_DAY = GET_DAY
        self.WAIT_HEADER = WAIT_HEADER
        self.WAIT_CR = WAIT_CR
        self.FOUND = FOUND
        self.state = self.GET_DAY

    def calculate_checksum(self, message):
        checksum = 0x55  # Initial value per VE.Direct protocol
        for byte in message:
            checksum -= byte
        checksum = checksum & 0xFF  # Ensure 8-bit result
        return bytes([checksum])

    def bytes_to_hex_string(self, byte_data):
        return ''.join([f'{b:02X}' for b in byte_data])

    def hex_to_bytes(self, hex_string):
        return bytes.fromhex(hex_string)

    def connect(self):
        try:
            self.ser = serial.Serial(self.port, self.baudrate, timeout=self.timeout)
            print(f"Connected to {self.port}")
            return True
        except Exception as e:
            print(f"Error opening serial port: {e}")
            return False

    def disconnect(self):
        if self.ser and self.ser.is_open:
            self.ser.close()

    def process_byte(self, byte):
        if not byte:
            return None

        self.buffer += byte

        if self.state == self.GET_DAY:
            # Build command for history day record
            self.base_command = '7' + str(50 + self.current_day) + '10' + '00'
            checksum = self.calculate_checksum(bytes.fromhex('0' + self.base_command))
            checksum_hex = self.bytes_to_hex_string(checksum)
            command = str.encode(':' + self.base_command + checksum_hex + '\n')
            self.ser.write(command)
            print('sent:', command)
            time.sleep(0.1)  # Wait for response
            self.state = self.WAIT_HEADER
            self.buffer = b''
            return None

        elif self.state == self.WAIT_HEADER:
            if self.buffer.endswith(self.base_command.encode()):
                self.state = self.WAIT_CR
                print('buffer:', self.buffer)
                self.buffer = b''

        elif self.state == self.WAIT_CR:
            if self.buffer.endswith(b'\n'):
                self.state = self.FOUND
                print('buffer:', self.buffer)
                response = self.buffer[64:68].decode('utf-8')
                response = bytes.fromhex(response)
                self.day_sequence = int.from_bytes(response, 'little')
                print('day_sequence:', self.day_sequence)
                return self.day_sequence

        elif self.state == self.FOUND:
            if len(self.buffer) >= 80:
                self.state = self.GET_DAY
                return self.day_sequence

        return None

    def get_history(self, days=10):
        if not self.connect():
            return

        try:
            self.current_day = 0
            while self.current_day < days:
                byte = self.ser.read(1)
                result = self.process_byte(byte)
                
                if result is not None:
                    print(f"Day {self.current_day} sequence: {result}")
                    self.current_day += 1
                    time.sleep(0.1)  # Small delay between requests
        except Exception as e:
            print(f"Error: {e}")
        finally:
            self.disconnect()

if __name__ == "__main__":
    # Example usage
    solar = SolarHistory('/dev/ttyUSB1')
    solar.get_history(10)

