-- This script is an example of saying hello.  A lot.

local PLANE_MODE_MANUAL = 0
local PLANE_MODE_AUTO = 10

-- Script to calculate distance from current position to waypoint (mission item 2)

-- Function to get distance to last waypoint
local function get_distance_to_last_waypoint()
  -- Get the total number of mission items
  local num_items = mission:num_commands()

  -- Check if there are any waypoints
  if num_items <= 1 then
      gcs:send_text(6, "Error: No waypoints in mission")
      return
  end

  -- Get the last mission item (index is num_items - 1)
  local wp = mission:get_item(num_items - 1)
  
  -- Check if waypoint is valid
  if wp == nil then
      gcs:send_text(6, "Error: Last waypoint not found")
      return
  end

  -- Get vehicle's current location
  local current_loc = ahrs:get_location()
  if current_loc == nil then
      gcs:send_text(6, "Error: Could not get current location")
      return
  end
  print(string.format("Wp (%.2f) (%.2f) (%.2f)", wp:x(), wp:y(), wp:z()))
  -- Extract waypoint location (Location object)
  local wp_loc = Location()
  wp_loc:lat(wp:x() * 1) -- Latitude in degrees * 10^7
  wp_loc:lng(wp:y() * 1) -- Longitude in degrees * 10^7
  wp_loc:alt(wp:z() * 1)      -- Altitude in cm (convert from meters)

  -- Calculate distance to waypoint (in meters)
  local distance = current_loc:get_distance(wp_loc)
  if distance == nil then
      gcs:send_text(6, "Error: Could not calculate distance")
      print("Error: Could not calculate distance")
      return nil
  end

  -- Send distance to ground station
  gcs:send_text(6, string.format("Distance to last WP: %.2f meters", distance))
  return distance
end


function update () -- periodic function that will be called
    local current_pos = ahrs:get_position() -- fetch the current position of the vehicle
    local home = ahrs:get_home()            -- fetch the home position of the vehicle
    local wp2 = mission:get_item(2)              -- fetch the second waypoint of the vehicle
    -- if current_pos and wp2 then            -- check that both a vehicle location, and home location are available
    -- -- get distance from  wp2
    
    --if mission finished
    -- local mission_state = mission:state()
    if mission:state() == mission.MISSION_COMPLETE then
        gcs:send_text(6, "Mission is finished")
        print("Mission is finished")
        -- disarm
        -- vehicle:arm(false)
    end

    local distance = get_distance_to_last_waypoint() -- calculate the distance from home in meters
    if distance and distance > 200 then -- if more then 200 meters away
      -- if mode is manual, set the mode to auto
      local mode = vehicle:get_mode()  
      if mode == PLANE_MODE_MANUAL then  -- relies on MIS_DONE_BEHAVE set to Manual ( behaviour after mission complete)
        -- set the autopilot to auto mode
        if param:get("MODE6") ~= nil then
          vehicle:set_mode(param:get("MODE6")) 
          print(string.format("Setting mode to %d", param:get("MODE6")))
          -- gcs:send_text(0, string.format("Setting mode to %d", param:get("MODE6")))
        end
      end
    
      print(string.format("DDistance: (%.2f) meters", distance)) 
    end
    -- gcs:send_text(0, string.format("Distance: (%.2f) meters", distance))
    -- servo.set_output_pwm(96, 1000 + distance) -- set the servo assigned function 96 (scripting3) to a proportional value

    return update, 10000 -- request "update" to be rerun again 1000 milliseconds (1 second) from now
  end
    

--   -- find the serial first (0) scripting serial port instance
-- local port = serial:find_serial(0)

--   if not port then
--       gcs:send_text(0, "No Scripting Serial Port")
--       print("No Scripting Serial Port")
--       return
--   end
--   print("Scripting Serial Port found") -- debug prints
  
  print("Starting position report script") -- debug print
  print(string.format("Parameter(MODE6): %d", param:get("MODE6")))
  vehicle:set_mode(PLANE_MODE_MANUAL)
  return update, 1000   -- request "update" to be the first time 1000 milliseconds (1 second) after script is loaded