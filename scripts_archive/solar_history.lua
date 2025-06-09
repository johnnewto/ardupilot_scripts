-- Solar History Reader Script
-- This script reads solar history data from a VE.Direct device using the same protocol
-- as the Python solar_history.py script

---@diagnostic disable: param-type-mismatch
---@diagnostic disable: need-check-nil
---@diagnostic disable: cast-local-type

-- Configuration
local baud_rate = 19200
local days_to_read = 10

-- States for the state machine
local GET_DAY = 1
local WAIT_HEADER = 2
local WAIT_CR = 3
local FOUND = 4

-- Initialize serial port
local port = assert(serial:find_serial(0), "Could not find Scripting Serial Port 0")
print("Scripting Serial Port found")

-- Begin the serial port
port:begin(baud_rate)
port:set_flow_control(0)

-- State machine variables
local state = FOUND
local buffer = ""
local pbuffer = ""
local base_command = ""
local current_day = 0
local day_sequence = nil

-- Helper function to calculate checksum
local function calculate_checksum(message)
    local checksum = 0x55 -- Initial value per VE.Direct protocol
    for i = 1, #message do
        checksum = checksum - string.byte(message, i)
    end
    return checksum & 0xFF -- Ensure 8-bit result
end

-- Helper function to convert bytes to hex string
local function bytes_to_hex_string(bytes)
    local hex = ""
    for i = 1, #bytes do
        hex = hex .. string.format("%02X", string.byte(bytes, i))
    end
    return hex
end

-- Process a single byte through the state machine
local function process_byte(byte)
    if not byte then
        return nil
    end

    -- buffer = buffer .. string.char(byte)

    -- length of pbuffer
    -- print("pbuffer length: " .. #pbuffer)

    if state == GET_DAY then
        -- Build command for history day record
        -- base_command = "7" .. tostring(50 + current_day) .. "10" .. "00"
        -- local checksum = calculate_checksum("0" .. base_command)
        -- local checksum_hex = string.format("%02X", checksum)
        -- local command = ":" .. base_command .. checksum_hex .. "\n"


        local len_written = port:writestring(':7501000EE' .. '\n') -- send a command get todays history to the solar inverter
        -- print(string.format(":7501000EE, len_writ: %d", len_written))

        -- local len_written = port:writestring(command)
        -- print("len_written: " .. len_written)
        -- delay 100ms


        -- state = WAIT_HEADER
        -- print("state: WAIT_HEADER")
        state = FOUND
        print("state: FOUND")

        buffer = ""
        return nil
    elseif state == WAIT_HEADER then
        -- gcs:send_text(6, byte)
        if buffer:sub(- #base_command) == base_command then
            state = WAIT_CR
            print("state: WAIT_CR")
            buffer = ""
        end
    elseif state == WAIT_CR then
        if buffer:sub(-1) == "\n" then
            state = FOUND
            print("state: FOUND")

            -- Extract the sequence number from positions 64-68
            local response = buffer:sub(65, 68)
            day_sequence = tonumber(response, 16)
            print("day_sequence: " .. tostring(day_sequence))
            return day_sequence
        end
        -- elseif state == FOUND then
        --     if #buffer >= 80 then
        --         state = GET_DAY
        --         print("state: GET_DAY")
        --         return day_sequence
        --     end
    end

    return nil
end

-- Main update function that runs periodically
local count = 0
local function update()
    count = count + 1
    print("state: " .. state)
    print(string.format("count: %d", count))
    if count % 5 == 0 then
        state = GET_DAY
        print("state: GET_DAY")
    end

    local n_bytes = port:available()
    print(string.format("Bytes: %d", n_bytes:toint()))
    while n_bytes > 0 do
        -- only read a max of 512 bytes in a go
        -- this limits memory consumption
        -- buffer = {} -- table to buffer data
        local bytes_target = n_bytes - math.min(n_bytes, 512)
        while n_bytes > bytes_target do
            local byte = port:read()
            pbuffer = pbuffer .. string.char(byte)
            n_bytes = n_bytes - 1
            local result = process_byte(byte)
            -- if result then
            --     gcs:send_text(6, string.format("Day %d sequence: %d", current_day, result))
            --     current_day = current_day + 1

            --     if current_day >= days_to_read then
            --         print("Completed reading all days")
            --         return nil -- Stop the script
            --     end
            -- end
        end
        -- print("pbuffer: " .. pbuffer)
        pbuffer = ""
    end


    return update, 500 -- Reschedule the loop with 100ms delay
end

-- Start the script
print("Starting Solar History reader script")

return update, 1000 -- Run after 1000ms before starting to reschedule
