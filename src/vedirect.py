# -*- coding: utf-8 -*-

import serial

class Vedirect:

    def __init__(self, serialport, timeout):
        self.serialport = serialport
        self.ser = serial.Serial(serialport, 19200, timeout=timeout)
        self.header1 = ord('\r')
        self.header2 = ord('\n')
        self.hexmarker = ord(':')
        self.delimiter = ord('\t')
        self.key = ''
        self.value = ''
        self.bytes_sum = 0;
        self.state = self.WAIT_HEADER
        self.dict = {}


    (HEX, WAIT_HEADER, IN_KEY, IN_VALUE, IN_CHECKSUM, IN_GET) = range(6)

    def input(self, byte):
        if byte == self.hexmarker and self.state != self.IN_CHECKSUM:
            self.state = self.HEX
            self.key = '';
            self.value = '';
            
        
        if self.state == self.WAIT_HEADER:
            self.bytes_sum += byte
            if byte == self.header1:
                self.state = self.WAIT_HEADER
            elif byte == self.header2:
                self.state = self.IN_KEY

            return None
        elif self.state == self.IN_KEY:
            self.bytes_sum += byte
            if byte == self.delimiter:
                if (self.key == 'Checksum'):
                    self.state = self.IN_CHECKSUM
                else:
                    self.state = self.IN_VALUE
            else:
                self.key += chr(byte)
            return None
        elif self.state == self.IN_VALUE:
            self.bytes_sum += byte
            if byte == self.header1:
                self.state = self.WAIT_HEADER
                self.dict[self.key] = self.value;
                self.key = '';
                self.value = '';
            else:
                self.value += chr(byte)
            return None
        elif self.state == self.IN_CHECKSUM:
            self.bytes_sum += byte
            self.key = ''
            self.value = ''
            self.state = self.WAIT_HEADER
            if (self.bytes_sum % 256 == 0):
                self.bytes_sum = 0
                return self.dict
            else:
                self.bytes_sum = 0

        elif self.state == self.HEX:
            self.bytes_sum = 0
            self.value += chr(byte)
            if self.value == ':7':
                self.state = self.IN_GET
            elif byte == self.header2:
                self.state = self.WAIT_HEADER
                # print('hex = ', self.value)

        elif self.state == self.IN_GET:
            self.bytes_sum += byte
            self.value += chr(byte)
            if byte == self.header2:
                self.state = self.WAIT_HEADER
                self.dict['Get'] = self.value;
                # print('get = ', self.value)
        else:
            raise AssertionError()

    def read_data_single(self):
        while True:
            data = self.ser.read()
            for single_byte in data:
                packet = self.input(single_byte)
                if (packet != None):
                    return packet
            

    def read_data_callback(self, callbackFunction):
        while True:
            data = self.ser.read()
            for byte in data:
                packet = self.input(byte)
                if (packet != None):
                    callbackFunction(packet)




    

if __name__ == '__main__':
    import time

    # Configuration
    PORT = '/dev/ttyUSB1'
    BAUDRATE = 19200  # Default baud rate for VE.Direct protocol
    TIMEOUT = 1       # Timeout in seconds for serial communication

    ve = Vedirect(PORT, TIMEOUT)
    #  encode the ve-direct get comand for the history
    hist_list = [':7501000EE\n', ':7511000ED\n', ':7521000EC\n', ':7531000EB\n', 
                 ':7541000EA\n', ':7551000E9\n', ':7561000E8\n', ':7571000E7\n', 
                 ':7581000E6\n', ':7591000E5\n', ':75A1000E4\n', ':75B1000E3\n',
                 ':75C1000E2\n', ':75D1000E1\n', ':75E1000E0\n', ':75F1000DF\n',
    ]
    
    count = 0
    while True:

        # print(count)
        data = ve.ser.read()
        if data:
            # print(data.decode(), end='')
            for single_byte in data:
                packet = ve.input(single_byte)
                if (packet != None):
                    break

            if packet:
                count += 1
                print(packet)
                get = hist_list[count % len(hist_list)]
                ve.ser.write(str.encode(get))
                # print('++++++++++++++++sent', get)

        else:
            print("No data")
            time.sleep(0.1)