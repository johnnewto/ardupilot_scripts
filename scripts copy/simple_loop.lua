-- This script is an example of saying hello.  A lot.
-- Pick a random number to send back
local number = math.random()

function update() -- this is the loop which periodically runs
  -- print("Sending hello world message") -- debug print
  -- gcs:send_text(0, string.format("hello, world (%.2f)", number)) -- send the traditional message with number
  -- print(string.format("hello, world (%.2f)", number)) 

  -- gcs:send_named_float('Lua Float',number) -- send a value
  number = number +  math.random() -- change the value

  return update, 50000 -- reschedules the loop
end

print("Starting simple_loop script") -- debug print
return update() -- run immediately before starting to reschedule
