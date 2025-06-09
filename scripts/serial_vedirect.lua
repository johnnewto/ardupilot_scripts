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

local SCRIPT_NAME            = 'serial_vedirect.lua'
local RUN_INTERVAL_MS        = 200

-- https://mavlink.io/en/messages/common.html#MAV_SEVERITY
local MAV_SEVERITY_EMERGENCY = 0
local MAV_SEVERITY_ALERT     = 1
local MAV_SEVERITY_CRITICAL  = 2
local MAV_SEVERITY_ERROR     = 3
local MAV_SEVERITY_WARNING   = 4
local MAV_SEVERITY_NOTICE    = 5
local MAV_SEVERITY_INFO      = 6

local baud_rate              = 19200      -- baud rate for the serial port
print("Starting VE.Direct reader script") -- debug print

-- Finds the serial port configured for scripting (instance 0 is the first port with SERIALx_PROTOCOL = 28, instance 1 is the second, etc.).
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
local IN_GET = 6

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


-- wrapper for gcs:send_text()
local function gcs_msg(severity, txt)
  gcs:send_text(severity, string.format('%s: %s', SCRIPT_NAME, txt))
end


function input(byte)
  if byte == hexmarker and state ~= IN_CHECKSUM then
    state = HEX
    key = ''
    value = ''
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
    value = value .. string.char(byte)
    if byte == header2 then
      state = WAIT_HEADER
    elseif value == ':7' then
      state = IN_GET
    end
  elseif state == IN_GET then
    bytes_sum = bytes_sum + byte
    value = value .. string.char(byte)
    if byte == header2 then
      state = WAIT_HEADER
      dict['Get'] = value
      -- print(string.format('IN_GET: %s', dict['Get']))
    end
  else
    error("Invalid state")
  end
end

-- update code
--  encode the ve-direct get comand for the history
-- 0x1050 ... 0x106E (0x1050=today, 0x1051=yesterday, ...) but little endian
local hist_list = { ':7501000EE\n', ':7511000ED\n', ':7521000EC\n', ':7531000EB\n',
  ':7541000EA\n', ':7551000E9\n', ':7561000E8\n', ':7571000E7\n',
  ':7581000E6\n', ':7591000E5\n', ':75A1000E4\n', ':75B1000E3\n',
  ':75C1000E2\n', ':75D1000E1\n', ':75E1000E0\n', ':75F1000DF\n',
  ':7601000DE\n', ':7611000DD\n', ':7621000DC\n', ':7631000DB\n',
  ':7641000DA\n', ':7651000D9\n', ':7661000D8\n', ':7671000D7\n',
  ':7681000D6\n', ':7691000D5\n', ':76A1000D4\n', ':76B1000D3\n',
  ':76C1000D2\n', ':76D1000D1\n', ':76E1000D0\n'
}


local count = 0
local skip_count = 2
function update() -- this is the loop which periodically runs
  local n_bytes = port:available()

  local bytes_target = n_bytes - math.min(n_bytes, 128)
  if n_bytes > 256 then
    gcs:send_text(MAV_SEVERITY_WARNING,
      string.format(" %s: Serial Bytes: %d", SCRIPT_NAME, n_bytes:toint()))
  end

  -- limit the number of bytes to process to 128
  while n_bytes > bytes_target do
    local byte = port:read()
    n_bytes = n_bytes - 1

    local packet = input(byte)
    if packet then
      count = count + 1
      -- Extract and print values
      local solar_power = tonumber(packet.PPV or 0)
      local solar_voltage = tonumber(packet.VPV or 0) / 1000.0
      local solar_current = solar_power / solar_voltage
      local battery_voltage = tonumber(packet.V or 0) / 1000.0
      local battery_current = tonumber(packet.I or 0) / 1000.0
      local history = packet.Get or ''

      -- send every 5th time
      if count % skip_count == 0 then
        gcs:send_text(MAV_SEVERITY_INFO,
          string.format("PPV: %.2f W, VPV: %.2f V, IPV: %.2f A, VB: %.2f, IB: %.2f A",
            solar_power, solar_voltage, solar_current, battery_voltage, battery_current))
        -- gcs_msg(MAV_SEVERITY_INFO, string.format("History: %s", history))
        gcs:send_text(MAV_SEVERITY_INFO, string.format("History: %s", history))

        local get_history = hist_list[count / skip_count % #hist_list]
        local len_written = port:writestring(get_history) -- send a command get todays history to the solar inverter
      end
    end
  end


  return update, RUN_INTERVAL_MS -- reschedules the loop
end

gcs_msg(MAV_SEVERITY_INFO, 'Initialized.')

return update() -- run immediately before starting to reschedule
