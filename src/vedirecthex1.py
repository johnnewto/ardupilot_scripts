##################################
# Created on Mar 13, 2022
# @author: lsimmons
# https://github.com/simmonslr/vedirecthex
##################################


'''
# vedirecthex
Command line Python script to GET/SET VE.Direct Hex Protocol for Victron devices.

Use examples:

python /src/vedirecthex.py -p /dev/ttyUSB1 -c :7A8ED00B9            # GET Example
python3 /opt/vedirect/vedirecthex.py -p /dev/ttyUSB1 -c :89DED00F609C4        # SET Example

Command examples:

################################
#  Load Control
################################
:7A8ED00B9		# get load output state
:7ABED00B6		# get load ctrl state
:8ABED0000B5		# set load ctrl state off
:8ABED0004B1		# set load ctrl state on
:8ABED0005B0		# set load ctrl state user1

:79CED00C5		# get switch low level
:79DED00C4		# get switch high level

:89CED002E098D		# set switch low level  to 23.50 volts
:89CED00FC08C0		# set switch low level  to 23.00 volts
:89CED00CA08F2		# set switch low level  to 22.50 volts
:89CED00980824		# set switch low level  to 22.00 volts

:89DED00280A91		# set switch high level  to 26.00 volts
:89DED00F609C4		# set switch high level  to 25.50 volts
:89DED00C409F6		# set switch high level  to 25.00 volts

:89CED00B2040E		# set switch low level  to 12.02 volts
:89DED001605A8		# set switch high level to 13.02 volts

################################
#  Street Light Function
################################
:7EDCC0095		# get streetlight function
:8EDCC0000??		# set streetlight function off
:8EDCC0001??		# set streetlight function on

################################
#  Miscellaneous
################################
:352			# application version
:451			# product ID
:64F			# restart
:7F0ED0071		# get battery max current
:8F0ED0064000C		# set battery max current to 10.0A


Calculating the checksum for commands:
################################
Message example from MPPT documentation
Set battery maximum current
set to 10.0A = 0x0064

:	start
8	set command	
F0	register (EDF0)
ED
00	flags
64	data (0064)
00
0C	checksum

0x55-0x08-0xF0-0xED-0x00-0x64-0x00 = 0x0C
################################
'''

import sys, getopt, serial
import argparse

ver = "v1.3 04/15/2022"

####################################
#                                  #
####################################
def main ( port, cmd ):

    print ( "===========")
    print ( "vedirecthex")
    print ( ver )
    print ( "port: " + port )
    ser = serial.Serial ( port, 19200, timeout=10 )
    ser.close()

    ser.open()
    ser.write ( str.encode ( ":451\n" ))        # get product ID
    read_val = ser.read ( size = 16 )
    print ( "prod: " + bytes.decode ( read_val ))
    ser.close()
    
    ser.open()
    print ( " cmd: " + cmd )
    command = str.encode ( cmd + "\n" )
    print('command: ', command)
    ser.write ( str.encode ( cmd + "\n" ))
    read_val = ser.read ( size = 256 )
    print ( " res: " + bytes.decode ( read_val ))
    ser.close()

####################################
#                                  #
####################################
if __name__ == '__main__':
    pass
    parser = argparse.ArgumentParser(description='VE.Direct Protocol Command Tool')
    parser.add_argument('-p', '--port', help='Serial port (e.g., /dev/ttyUSB1)', default='/dev/ttyUSB1')
    parser.add_argument('-c', '--command', help='HEX command (e.g., 7A8ED00B9)', default=':7501000EE')
    args = parser.parse_args()
    # main ( sys.argv[1:] )
    # cmd = ':7A8ED00B9'  
    #  pass in command line arguments
    print('args.port: ', args.port)
    print('args.command: ', args.command)
    main(args.port, args.command)
