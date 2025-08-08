print("Starting simple_loop script") -- debug print

local RELAY_NUM = 4                  -- this maps to relay 5 (in code ArduPilot relays are zero-indexed)

local RELAY_SHOULD_BE_ON = true

function update()
  if RELAY_SHOULD_BE_ON then
    relay:on(RELAY_NUM)
    RELAY_SHOULD_BE_ON = false
    print("!!!! Relay " .. (RELAY_NUM + 1) .. " On !!!!")
  else
    relay:off(RELAY_NUM)
    RELAY_SHOULD_BE_ON = true
    print("!!!! Relay " .. (RELAY_NUM + 1) .. " Off !!!!")
  end
  return update, 2000
end

print("Starting Relay " .. (RELAY_NUM + 1) .. " script") -- debug print
return update()                                          -- run immediately before starting
