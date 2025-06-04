-- this script reads data from a serial port and dumps it to a file

---@diagnostic disable: param-type-mismatch
---@diagnostic disable: need-check-nil
---@diagnostic disable: cast-local-type

local file_name = 'raw serial dump.txt'
local file_name_plain = 'serial dump.txt'
local baud_rate = 57600 -- baud rate for the serial port
print("Starting serial dump script") -- debug print

-- find the serial first (0) scripting serial port instance
-- SERIALx_PROTOCOL 28
local port = assert(serial:find_serial(0),"Could not find Scripting Serial Port 0")
print("Scripting Serial First Port found") -- debug print
-- local port = assert(serial:find_serial(1),"Could not find Scripting Serial Port 1")
-- print("Scripting Serial Second Port found") -- debug print

-- make a file
local file = assert(io.open(file_name, "w"),"Could not create file " .. file_name)
file:close()
file = assert(io.open(file_name_plain, "w"),"Could not create file " .. file_name)
file:close()

-- begin the serial port
port:begin(baud_rate)
port:set_flow_control(0)

function update() -- this is the loop which periodically runs

  local n_bytes = port:available()
  while n_bytes > 0 do
    print(string.format("Bytes available: %d", n_bytes:toint()))
    -- only read a max of 515 bytes in a go
    -- this limits memory consumption
    local buffer = {} -- table to buffer data
    local bytes_target = n_bytes - math.min(n_bytes, 512)
    while n_bytes > bytes_target do
      table.insert(buffer,port:read())
      n_bytes = n_bytes - 1
    end

    -- write as decoded
    file = io.open(file_name, "a")
    file:write(table.concat(buffer,',') .. '\n')
    file:close()

    -- write as plain text
    file = io.open(file_name_plain, "a")
    file:write(string.char(table.unpack(buffer)))
    file:close()

  end

  return update, 1000 -- reschedules the loop
end

return update() -- run immediately before starting to reschedule
