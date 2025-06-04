-- victron_mppt_serial.lua
local UART_NUM = 2 -- SERIAL2
local BAUD_RATE = 19200 -- VE.Direct baud rate

local function init_serial(num)
    local uart = serial:find_serial(num)
    if uart == nil then
        gcs:send_text(6, "Error: Could not find serial port " .. num)
        return nil
    end
    uart:begin(BAUD_RATE)
    if not uart:available() then
        gcs:send_text(6, "Error: Serial port not active")
        return nil
    end
    gcs:send_text(6, "----------------Serial port initialized: UART" .. num)
    return uart
end

local function parse_ve_direct(data)
    local solar_watts, solar_voltage
    for line in data:gmatch("[^\r\n]+") do
        local key, value = line:match("(%w+)%s+(%w+)")
        if key and value then
            if key == "PPV" then
                solar_watts = tonumber(value)
            elseif key == "VPV" then
                solar_voltage = tonumber(value) / 1000
            end
        end
    end
    return solar_watts, solar_voltage
end

local function read_victron_data(uart)
    if not uart then
        gcs:send_text(6, "Serial port not initialized")
        return
    end
    local data = uart:read()
    if data and #data > 0 then
        local watts, voltage = parse_ve_direct(data)
        if watts and voltage then
            gcs:send_text(6, string.format("Solar Power: %.2f W, Solar Voltage: %.2f V", watts, voltage))
        else
            gcs:send_text(6, "No valid data parsed")
        end
    else
        gcs:send_text(6, "No serial data received")
    end
end

-- local uart = init_serial(0)
-- local uart = init_serial(1)
local uart = init_serial(2)
-- local uart = init_serial(3)
-- local uart = init_serial(4)
-- local uart = init_serial(5)
-- local uart = init_serial(6)
-- local uart = init_serial(7)
local function update()
    
    if uart then
        read_victron_data(uart)
    end
    return update, 1000
end

gcs:send_text(6, "Victron MPPT serial reader started")

return update, 1000