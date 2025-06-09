-- this script reads VE.Direct data from a serial port and sends formatted values on the gcs

---@diagnostic disable: param-type-mismatch
---@diagnostic disable: need-check-nil
---@diagnostic disable: cast-local-type
-- - `serial_vedirect.lua` : A Lua script that reads VE.Direct protocol data from a serial port and sends formatted values to the Ground Control Station (GCS). This script is particularly useful for monitoring solar and battery data from Victron Energy devices.

--   Features:
--   - Reads VE.Direct protocol data at 19200 baud rate
--   - Parses solar power (PPV), solar voltage (VPV), solar current (IPV), battery voltage (BV), and battery current (BI)
--   - Sends formatted data to GCS every second
--   - Handles checksum validation and hex data
--   - Uses Scripting Serial Port 0 for communication

--   Usage:
--   1. Connect a Victron Energy device to Scripting Serial Port 0
--   2. Configure the device for VE.Direct protocol output
--   3. Load the script in ArduPilot
--   4. The script will automatically start sending formatted data to GCS

--   Hardware Requirements:
--   - Victron Energy device with VE.Direct output
--   - Serial connection to Scripting Serial Port 0
--   - Proper voltage level conversion if needed (Victron devices typically use 5V logic)

--   Output Format:
--   ```
--   PPV: XX.XX W, VPV: XX.XX V, IPV: XX.XX A, BV: XX.XX V, BI: XX.XX A
--   ```
--   Where:
--   - PPV: Solar Power in Watts
--   - VPV: Solar Voltage in Volts
--   - IPV: Solar Current in Amperes
--   - BV: Battery Voltage in Volts
--   - BI: Battery Current in Amperes

--   - Implements a state machine for robust protocol parsing
-- - Processes data in real-time with minimal latency

-- VE.Direct Protocol Implementation:
-- - Uses a 5-state state machine for parsing:
--   1. WAIT_HEADER: Waiting for protocol header
--   2. IN_KEY: Reading key field
--   3. IN_VALUE: Reading value field
--   4. IN_CHECKSUM: Validating checksum
--   5. HEX: Handling hex data
-- - Validates data integrity using checksums
-- - Handles special characters and hex markers
-- - Maintains protocol synchronization


local baud_rate = 19200                   -- baud rate for the serial port
print("Starting VE.Direct reader script") -- debug print

-- find the serial first (0) scripting serial port instance
local port = assert(serial:find_serial(0), "Could not find Scripting Serial Port 0")
print("Scripting Serial First Port found") -- debug print

-- begin the serial port
port:begin(baud_rate)
port:set_flow_control(0)

-- VE.Direct states
local HEX = 1
local WAIT_HEADER = 2
local IN_KEY = 3
local IN_VALUE = 4
local IN_CHECKSUM = 5

-- VE.Direct parser state
local header1 = string.byte('\r')
local header2 = string.byte('\n')
local hexmarker = string.byte(':')
local delimiter = string.byte('\t')
local key = ''
local value = ''
local bytes_sum = 0
local state = WAIT_HEADER
local dict = {}

function input(byte)
  if byte == hexmarker and state ~= IN_CHECKSUM then
    state = HEX
  end

  if state == WAIT_HEADER then
    bytes_sum = bytes_sum + byte
    if byte == header1 then
      state = WAIT_HEADER
    elseif byte == header2 then
      state = IN_KEY
    end
    return nil
  elseif state == IN_KEY then
    bytes_sum = bytes_sum + byte
    if byte == delimiter then
      if key == 'Checksum' then
        state = IN_CHECKSUM
      else
        state = IN_VALUE
      end
    else
      key = key .. string.char(byte)
    end
    return nil
  elseif state == IN_VALUE then
    bytes_sum = bytes_sum + byte
    if byte == header1 then
      state = WAIT_HEADER
      dict[key] = value
      key = ''
      value = ''
    else
      value = value .. string.char(byte)
    end
    return nil
  elseif state == IN_CHECKSUM then
    bytes_sum = bytes_sum + byte
    key = ''
    value = ''
    state = WAIT_HEADER
    if (bytes_sum % 256 == 0) then
      bytes_sum = 0
      return dict
    else
      bytes_sum = 0
    end
  elseif state == HEX then
    bytes_sum = 0
    if byte == header2 then
      state = WAIT_HEADER
    end
  else
    error("Invalid state")
  end
end

local last_sent = 0
function update() -- this is the loop which periodically runs
  local n_bytes = port:available()
  -- print(string.format("Bytes: %d", n_bytes:toint()))
  while n_bytes > 0 do
    local byte = port:read()
    n_bytes = n_bytes - 1

    local packet = input(byte)
    if packet then
      -- dump all remaining bytes
      print(string.format("Remaining Bytes: %d", n_bytes:toint()))
      while n_bytes > 0 do
        local byte = port:read()
        n_bytes = n_bytes - 1
      end

      last_sent = last_sent + 1
      -- Extract and print values
      local solar_power = tonumber(packet.PPV or 0)
      local solar_voltage = tonumber(packet.VPV or 0) / 1000.0
      local solar_current = solar_power / solar_voltage
      local battery_voltage = tonumber(packet.V or 0) / 1000.0
      local battery_current = tonumber(packet.I or 0) / 1000.0

      -- send every 5th time
      if last_sent % 5 == 0 then
        gcs:send_text(6,
          string.format("PPV: %.2f W, VPV: %.2f V, IPV: %.2f A, BV: %.2f, BI: %.2f A", solar_power, solar_voltage,
            solar_current, battery_voltage, battery_current))
      end
    end
  end


  return update, 500 -- reschedules the loop
end

return update, 5000 -- run immediately before starting to reschedule
