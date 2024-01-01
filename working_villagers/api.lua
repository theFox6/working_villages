--TODO: split this into single modules

local log    = working_villages.require("log")
local cmnp   = modutil.require("check_prefix","venus")
local colors = working_villages.require("jobs/dyemixer_recipes").colors
local aggro  = working_villages.require("aggro")
assert(#colors > 0)

working_villages.animation_frames = {
  STAND     = { x=  0, y= 79, },
  LAY       = { x=162, y=166, },
  WALK      = { x=168, y=187, },
  MINE      = { x=189, y=198, },
  WALK_MINE = { x=200, y=219, },
  SIT       = { x= 81, y=160, },
}

working_villages.registered_villagers = {}

working_villages.registered_jobs      = {}

working_villages.registered_eggs      = {}

-- records failed node place attempts to prevent repeating mistakes
-- key=minetest.pos_to_string(pos) val=(os.clock()+180)
local failed_pos_data = {}
local failed_pos_time = 0

-- remove old positions
local function failed_pos_cleanup()
	-- build a list of all items to discard
	local discard_tab = {}
	local now = os.clock()
	for key, val in pairs(failed_pos_data) do
		if now >= val then
			discard_tab[key] = true
		end
	end
	-- discard the old entries
	for key, _ in pairs(discard_tab) do
		failed_pos_data[key] = nil
	end
end

-- add a failed place position
function working_villages.failed_pos_record(pos)
	local key = minetest.hash_node_position(pos)
	failed_pos_data[key] = os.clock() + 180 -- mark for 3 minutes

	-- cleanup if more than 1 minute has passed since the last cleanup
	if os.clock() > failed_pos_time then
		failed_pos_time = os.clock() + 60
		failed_pos_cleanup()
	end
end

-- check if a position is marked as failed and hasn't expired
function working_villages.failed_pos_test(pos)
	local key = minetest.hash_node_position(pos)
	local exp = failed_pos_data[key]
	return exp ~= nil and exp >= os.clock()
end

-- working_villages.is_job reports whether a item is a job item by the name.
function working_villages.is_job(item_name)
  if working_villages.registered_jobs[item_name] then
    return true
  end
  return false
end

-- working_villages.is_villager reports whether a name is villager's name.
function working_villages.is_villager(name)
  if working_villages.registered_villagers[name] then
    return true
  end
  return false
end

---------------------------------------------------------------------

-- working_villages.villager represents a table that contains common methods
-- for villager object.
-- this table must be contains by a metatable.__index of villager self tables.
-- minetest.register_entity set initial properties as a metatable.__index, so
-- this table's methods must be put there.
working_villages.villager = {}

-- working_villages.villager.get_inventory returns a inventory of a villager.
function working_villages.villager:get_inventory()
  return minetest.get_inventory {
    type = "detached",
    name = self.inventory_name,
  }
end

-- working_villages.villager.get_job_name returns a name of a villager's current job.
function working_villages.villager:get_job_name()
  local inv = self:get_inventory()

  local new_job = self.object:get_luaentity().new_job
  if new_job ~= "" then
    self.object:get_luaentity().new_job = ""
    local job_stack = ItemStack(new_job)
    inv:set_stack("job", 1, job_stack)
    return new_job
  end

  return inv:get_stack("job", 1):get_name()
end

-- working_villages.villager.get_job returns a villager's current job definition.
function working_villages.villager:get_job()
  local name = self:get_job_name()
  if name ~= "" then
    return working_villages.registered_jobs[name]
  end
  return nil
end

-- working_villages.villager.is_enemy returns if an object is an enemy.
function working_villages.villager:is_enemy(obj)
  log.verbose("villager %s checks if %s is hostile",self.inventory_name,obj)
  --return false
  if self.aggro         == nil then return false end
  if self.aggro.players == nil then return false end
  -- TODO entity name if no player name ?
  local name = obj:get_player_name()
  local like = self.aggro.players[name] 
  if like == nil then return false end
  -- TODO check other villagers' aggro & village's aggro
  -- local village_name = self.village_name
  -- local village      = working_villages.get_village(village_name)
  -- for _,villager in ipairs(village.villagers) do
  --   like += villager.aggro.players[name] * self.aggro.transitive_factor
  -- end
  -- like += village.aggro.players[name] * self.aggro.transitive_factor
  return like < 0
end

-- working_villages.villager.get_nearest_player returns a player object who
-- is the nearest to the villager, the position of and the distance to the player.
function working_villages.villager:get_nearest_player(range_distance,pos)
  local min_distance = range_distance
  local player,ppos
  local position = pos or self.object:get_pos()

  local all_objects = minetest.get_objects_inside_radius(position, range_distance)
  for _, object in pairs(all_objects) do
    if object:is_player() then
      local player_position = object:get_pos()
      local distance = vector.distance(position, player_position)

      if distance < min_distance then
        min_distance = distance
        player = object
        ppos = player_position
      end
    end
  end
  return player,ppos,min_distance
end
function working_villages.villager:get_near_players(range_distance,pos)
  local min_distance = range_distance
  local result   = {}
  local position = pos or self.object:get_pos()

  local all_objects = minetest.get_objects_inside_radius(position, range_distance)
  for _, object in pairs(all_objects) do
    if object:is_player() then
      local player_position = object:get_pos()
      local distance = vector.distance(position, player_position)
      if distance < min_distance then
        min_distance = distance
      end
      local data = {
        player  =object,
        position=player_position,
        distance=distance,
      }
      table.insert(result, data)
    end
  end
  return result,min_distance
end
function working_villages.villager:get_nearest_player_with_condition(range_distance,pos, condition)
  local min_distance = range_distance
  local player,ppos
  local position = pos or self.object:get_pos()

  local all_objects = minetest.get_objects_inside_radius(position, range_distance)
  for _, object in pairs(all_objects) do
    local inv = object:get_inventory()
    if --object:is_player() and -- ehh, is there a reason why a thief shouldn't rob a non-player ?
       condition(inv)
    then
      local player_position = object:get_pos()
      local distance = vector.distance(position, player_position)

      if distance < min_distance then
        min_distance = distance
        player = object
        ppos = player_position
      end
    end
  end
  return player,ppos,min_distance
end

-- working_villages.villager.get_nearest_enemy returns an enemy who is the nearest to the villager.
function working_villages.villager:get_nearest_enemy(range_distance)
  local enemy
  local min_distance = range_distance
  local position = self.object:get_pos()

  local all_objects = minetest.get_objects_inside_radius(position, range_distance)
  for _, object in pairs(all_objects) do
    if self:is_enemy(object) then
      local object_position = object:get_pos()
      local distance = vector.distance(position, object_position)

      if distance < min_distance then
        min_distance = distance
        enemy = object
      end
    end
  end
  return enemy
end
-- working_villages.villager.get_nearest_item_by_condition returns the position of
-- an item that returns true for the condition
function working_villages.villager:get_nearest_item_by_condition(cond, range_distance)
  local max_distance=range_distance
  if type(range_distance) == "table" then
    max_distance=math.max(math.max(range_distance.x,range_distance.y),range_distance.z)
  end
  local item = nil
  local min_distance = max_distance
  local position = self.object:get_pos()

  local all_objects = minetest.get_objects_inside_radius(position, max_distance)
  for _, object in pairs(all_objects) do
    if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "__builtin:item" then
      local found_item = ItemStack(object:get_luaentity().itemstring):to_table()
      if found_item then
        if cond(found_item) then
          local item_position = object:get_pos()
          local distance = vector.distance(position, item_position)

          if distance < min_distance then
            min_distance = distance
            item = object
          end
        end
      end
    end
  end
  return item;
end

-- working_villages.villager.get_front returns a position in front of the villager.
function working_villages.villager:get_front()
  local direction = self:get_look_direction()
  if math.abs(direction.x) >= 0.5 then
    if direction.x > 0 then	direction.x = 1	else direction.x = -1 end
  else
    direction.x = 0
  end

  if math.abs(direction.z) >= 0.5 then
    if direction.z > 0 then	direction.z = 1	else direction.z = -1 end
  else
    direction.z = 0
  end

  --direction.y = direction.y - 1

  return vector.add(vector.round(self.object:get_pos()), direction)
end

-- working_villages.villager.get_front_node returns a node that exists in front of the villager.
function working_villages.villager:get_front_node()
  local front = self:get_front()
  return minetest.get_node(front)
end

-- working_villages.villager.get_back returns a position behind the villager.
function working_villages.villager:get_back()
  local direction = self:get_look_direction()
  if math.abs(direction.x) >= 0.5 then
    if direction.x > 0 then	direction.x = -1
    else direction.x = 1 end
  else
    direction.x = 0
  end

  if math.abs(direction.z) >= 0.5 then
    if direction.z > 0 then	direction.z = -1
    else direction.z = 1 end
  else
    direction.z = 0
  end

  --direction.y = direction.y - 1

  return vector.add(vector.round(self.object:get_pos()), direction)
end

-- working_villages.villager.get_back_node returns a node that exists behind the villager.
function working_villages.villager:get_back_node()
  local back = self:get_back()
  return minetest.get_node(back)
end

-- working_villages.villager.get_look_direction returns a normalized vector that is
-- the villagers's looking direction.
function working_villages.villager:get_look_direction()
  local yaw = self.object:get_yaw()
  return vector.normalize{x = -math.sin(yaw), y = 0.0, z = math.cos(yaw)}
end

-- working_villages.villager.set_animation sets the villager's animation.
-- this method is wrapper for self.object:set_animation.
function working_villages.villager:set_animation(frame)
  self.object:set_animation(frame, 15, 0)
  if frame == working_villages.animation_frames.LAY then
    local dir = self:get_look_direction()
    local dirx = math.abs(dir.x)*0.5
    local dirz = math.abs(dir.z)*0.5
    self.object:set_properties({collisionbox={-0.5-dirx, 0, -0.5-dirz, 0.5+dirx, 0.5, 0.5+dirz}})
  else
    self.object:set_properties({collisionbox={-0.25, 0, -0.25, 0.25, 1.75, 0.25}})
  end
end

-- working_villages.villager.set_yaw_by_direction sets the villager's yaw
-- by a direction vector.
function working_villages.villager:set_yaw_by_direction(direction)
  self.object:set_yaw(math.atan2(direction.z, direction.x) - math.pi / 2)
end

-- working_villages.villager.get_wield_item_stack returns the villager's wield item's stack.
function working_villages.villager:get_wield_item_stack()
  local inv = self:get_inventory()
  return inv:get_stack("wield_item", 1)
end

-- working_villages.villager.set_wield_item_stack sets villager's wield item stack.
function working_villages.villager:set_wield_item_stack(stack)
  local inv = self:get_inventory()
  inv:set_stack("wield_item", 1, stack)
end

-- working_villages.villager.add_item_to_main add item to main slot.
-- and returns leftover.
function working_villages.villager:add_item_to_main(stack)
  local inv = self:get_inventory()
  return inv:add_item("main", stack)
end

function working_villages.villager:replace_item_from_main(rstack,astack)
  local inv = self:get_inventory()
  inv:remove_item("main", rstack)
  inv:add_item("main", astack)
end

-- working_villages.villager.move_main_to_wield moves itemstack from main to wield.
-- if this function fails then returns false, else returns true.
function working_villages.villager:move_main_to_wield(pred)
  local inv = self:get_inventory()
  local main_size = inv:get_size("main")

  for i = 1, main_size do
    local stack = inv:get_stack("main", i)
    if pred(stack:get_name()) then
      local wield_stack = inv:get_stack("wield_item", 1)
      inv:set_stack("wield_item", 1, stack)
      inv:remove_item("main", stack)
      inv:add_item("main", wield_stack)
      return true
    end
  end
  return false
end
function working_villages.villager:get_wielded_item()
  return self:get_wield_item_stack()
end
function working_villages.villager:set_wielded_item(item)
  return self:set_wield_item_stack(item)
end

-- working_villages.villager.is_named reports the villager is still named.
function working_villages.villager:is_named()
  return self.nametag ~= ""
end

-- working_villages.villager.has_item_in_main reports whether the villager has item.
function working_villages.villager:has_item_in_main(pred)
  local inv = self:get_inventory()
  local stacks = inv:get_list("main")

  for _, stack in ipairs(stacks) do
    local itemname = stack:get_name()
    if pred(itemname) then
      return true
    end
  end
end

-- working_villages.villager.change_direction change direction to destination and velocity vector.
function working_villages.villager:change_direction(destination)
  local position = self.object:get_pos()
  local direction = vector.subtract(destination, position)
  direction.y = 0
  local velocity = vector.multiply(vector.normalize(direction), 1.5)

  self.object:set_velocity(velocity)
  self:set_yaw_by_direction(direction)
end

-- working_villages.villager.change_direction_randomly change direction randonly.
function working_villages.villager:change_direction_randomly()
  local direction = {
    x = math.random(0, 5) * 2 - 5,
    y = 0,
    z = math.random(0, 5) * 2 - 5,
  }
  -- TODO check whether it's safe so we don't wander off a cliff #49
  local velocity = vector.multiply(vector.normalize(direction), 1.5)
  self.object:set_velocity(velocity)
  self:set_yaw_by_direction(direction)
  self:set_animation(working_villages.animation_frames.WALK)
end

-- working_villages.villager.get_timer get the value of a counter.
function working_villages.villager:get_timer(timerId)
  return self.time_counters[timerId]
end

-- working_villages.villager.set_timer set the value of a counter.
function working_villages.villager:set_timer(timerId,value)
  assert(type(value)=="number","timers need to be countable")
  self.time_counters[timerId]=value
end

-- working_villages.villager.clear_timers set all counters to 0.
function working_villages.villager:clear_timers()
  for timerId,_ in pairs(self.time_counters) do
    self.time_counters[timerId] = 0
  end
end

-- working_villages.villager.count_timer count a counter up by 1.
function working_villages.villager:count_timer(timerId)
  if not self.time_counters[timerId] then
    log.info("villager %s timer %q was not initialized", self.inventory_name,timerId)
    self.time_counters[timerId] = 0
  end
  self.time_counters[timerId] = self.time_counters[timerId] + 1
end

-- working_villages.villager.count_timers count all counters up by 1.
function working_villages.villager:count_timers()
  for id, counter in pairs(self.time_counters) do
    self.time_counters[id] = counter + 1
  end
end

-- working_villages.villager.timer_exceeded if a timer exceeds the limit it will be reset and true is returned
function working_villages.villager:timer_exceeded(timerId,limit)
  if self:get_timer(timerId)>=limit then
    self:set_timer(timerId,0)
    return true
  else
    return false
  end
end

-- working_villages.villager.update_infotext updates the infotext of the villager.
function working_villages.villager:update_infotext()
  local infotext = ""
  local job_name = self:get_job()

  if job_name ~= nil then
    job_name = job_name.description
    infotext = infotext .. job_name .. "\n"
  else
    infotext = infotext .. "no job\n"
    self.disp_action = "inactive"
  end
  infotext = infotext .. "[Owner] : " .. self.owner_name
  infotext = infotext .. "\nthis villager is " .. self.disp_action
  if self.pause then
    infotext = infotext .. ", [paused]"
  end
  self.object:set_properties{infotext = infotext}
end

-- working_villages.villager.is_near checks if the villager is within the radius of a position
function working_villages.villager:is_near(pos, distance)
  local p = self.object:get_pos()
  p.y = p.y + 0.5
  return vector.distance(p, pos) < distance
end

function working_villages.villager:handle_liquids()
  local ctrl = self.object
  local inside_node = minetest.get_node(self.object:get_pos())
  -- perhaps only when changed
  if minetest.get_item_group(inside_node.name,"liquid") > 0 then
    -- swim
    local viscosity = minetest.registered_nodes[inside_node.name].liquid_viscosity
    ctrl:set_acceleration{x = 0, y = -self.initial_properties.weight/(100*viscosity), z = 0}
  elseif minetest.registered_nodes[inside_node.name].climbable then
    --go down slowly
    ctrl:set_acceleration{x = 0, y = -0.1, z = 0}
  else
    -- fall
    ctrl:set_acceleration{x = 0, y = -self.initial_properties.weight, z = 0}
  end
end

function working_villages.villager:jump()
  local ctrl = self.object
  local below_node = minetest.get_node(vector.subtract(ctrl:get_pos(),{x=0,y=1,z=0}))
  local velocity = ctrl:get_velocity()
  if below_node.name == "air" then return false end
  local jump_force = math.sqrt(self.initial_properties.weight) * 1.5
  if minetest.get_item_group(below_node.name,"liquid") > 0 then
    local viscosity = minetest.registered_nodes[below_node.name].liquid_viscosity
    jump_force = jump_force/(viscosity*100)
  end
  ctrl:set_velocity{x = velocity.x, y = jump_force, z = velocity.z}
end

local function walkable(node)
	-- copied from pathfinder
	--if string.find(node.name,"doors:") then
	--	return false
	--else
	if minetest.registered_nodes[node.name]~= nil then
		return minetest.registered_nodes[node.name].walkable
	else
		return true
	end
	--end
end
--working_villages.villager.handle_obstacles(ignore_fence,ignore_doors)
--if the villager hits a walkable he wil jump
--if ignore_fence is false the villager will not jump over fences
--if ignore_doors is false and the villager hits a door he opens it
function working_villages.villager:handle_obstacles(ignore_fence,ignore_doors)
  local velocity = self.object:get_velocity()
  local front_diff = self:get_look_direction()
  for i,v in pairs(front_diff) do
    local front_pos = vector.new(0,0,0)
    front_pos[i] = v
    front_pos = vector.add(front_pos, vector.round(self.object:get_pos()))
    front_pos.y = math.floor(self.object:get_pos().y)+0.5
    local above_node = vector.new(front_pos)
    local front_node = minetest.get_node(front_pos)
    above_node = vector.add(above_node,{x=0,y=1,z=0})
    above_node = minetest.get_node(above_node)
    if --string.find(front_node.name, "mobs:fence") or -- #42
    (minetest.get_item_group(front_node.name, "fence") > 0 and not(ignore_fence)) then
      self:change_direction_randomly()
    elseif string.find(front_node.name,"doors:door") and not(ignore_doors) then
      local door = doors.get(front_pos)
      local door_dir = vector.apply(minetest.facedir_to_dir(front_node.param2),math.abs)
      local villager_dir = vector.round(vector.apply(front_diff,math.abs))
      if vector.equals(door_dir,villager_dir) then
        if door:state() then
          door:close()
        else
          door:open()
        end
      end
    -- TODO trap doors & ladders
    elseif walkable(front_node) --minetest.registered_nodes[front_node.name].walkable
      and not(walkable(above_node)) then --not(minetest.registered_nodes[above_node.name].walkable) then
      if velocity.y == 0 then
        local nBox = minetest.registered_nodes[front_node.name]
        if nBox ~= nil then nBox = nBox.node_box end
        if (nBox == nil) then
          nBox = {-0.5,-0.5,-0.5,0.5,0.5,0.5}
        else
          nBox = nBox.fixed
        end
        if type(nBox[1])=="number" then
          nBox = {nBox}
        end
        for _,box in pairs(nBox) do --TODO: check rotation of the nodebox
          local nHeight = (box[5] - box[2]) + front_pos.y
          if nHeight > self.object:get_pos().y + .5 then
            self:jump()
          end
        end
      end
    end
  end
  if not ignore_doors then
    local back_pos = self:get_back()
    if string.find(minetest.get_node(back_pos).name,"doors:door") then
      local door = doors.get(back_pos)
      door:close()
    end
  end
end

-- working_villages.villager.pickup_item pickup items placed and put it to main slot.
function working_villages.villager:pickup_item()
  local pos = self.object:get_pos()
  local radius = 1.0
  local all_objects = minetest.get_objects_inside_radius(pos, radius)

  for _, obj in ipairs(all_objects) do
    if not obj:is_player() and obj:get_luaentity() and obj:get_luaentity().itemstring then
      local itemstring = obj:get_luaentity().itemstring
      local stack = ItemStack(itemstring)
      if stack and stack:to_table() then
        local name = stack:to_table().name

        if minetest.registered_items[name] ~= nil then
          local inv = self:get_inventory()
          local leftover = inv:add_item("main", stack)

          minetest.add_item(obj:get_pos(), leftover)
          obj:get_luaentity().itemstring = ""
          obj:remove()
        end
      end
    end
  end
end

-- working_villages.villager.get_job_data get a job data field
function working_villages.villager:get_job_data(key)
  local actual_job_data = self.job_data[self:get_job_name()]
  if actual_job_data == nil then
    return nil
  end
  return actual_job_data[key]
end

-- working_villages.villager.set_job_data set a job data field
function working_villages.villager:set_job_data(key, value)
  local actual_job_data = self.job_data[self:get_job_name()]
  if actual_job_data == nil then
    actual_job_data = {}
    self.job_data[self:get_job_name()] = actual_job_data
  end
  actual_job_data[key] = value
end

-- working_villages.villager:new returns a new villager object.
function working_villages.villager:new(o)
  return setmetatable(o or {}, {__index = self})
end

working_villages.require("villager_state")

-- working_villages.villager.is_active check if the villager is paused.
-- deprecated check self.pause instesad
function working_villages.villager:is_active()
  print("self:is_active is deprecated: check self.pause directly it's a boolean value")
  --return self.pause == "active"
  return self.pause
end

--working_villages.villager.set_paused set the villager to paused state
--deprecated use set_pause
function working_villages.villager:set_paused(reason)
  print("self:set_paused() is deprecated use self:set_pause() and self:set_displayed_action() instead")
  --[[
  self.pause = "resting"
  self.object:set_velocity{x = 0, y = 0, z = 0}
  self:set_animation(working_villages.animation_frames.STAND)
  ]]
  self:set_pause(true)
  self:set_displayed_action(reason or "resting")
end

working_villages.require("async_actions")

-- compatibility with like player object
function working_villages.villager:get_player_name()
  --return self.object:get_player_name()
  return self.nametag
end
function working_villages.villager:get_properties()
	return self.object:get_properties()
end
function working_villages.villager:get_hp()
	return self.object:get_hp()
end
function working_villages.villager:set_hp(hp)
	return self.object:set_hp(hp)
end

-- TODO we need ref:is_player() to return true
--if pointed_thing.type == "object" then
--local ref = pointed_thing.ref
--local ent = ref:get_luaentity()
--ref:is_player() => false
--ent:is_player() => true
function working_villages.villager:is_player()
  -- TODO I think we're supposed to return true here:
  --if player and player:is_player() and not player.is_fake_player then
  --return false
  assert(self.is_fake_player)
  local name = self:get_player_name()
  if name == nil or name == "" then
	  return false
  end
  return true
end

function working_villages.villager:get_wield_index()
  return 1
end

--deprecated
function working_villages.villager:set_state(id)
  if id == "idle" then
    print("the idle state is deprecated")
  elseif id == "goto_dest" then
    print("use self:go_to(pos) instead of self:set_state(\"goto\")")
    self:go_to(self.destination)
  elseif id == "job" then
    print("the job state is not nessecary anymore")
  elseif id == "dig_target" then
    print("use self:dig(pos,collect_drops) instead of self:set_state(\"dig_target\")")
    self:dig(self.target,true)
  elseif id == "place_wield" then
    print("use self:place(itemname,pos) instead of self:set_state(\"place_wield\")")
    local wield_stack = self:get_wield_item_stack()
    self:place(wield_stack:get_name(),self.target)
  end
end

---------------------------------------------------------------------

-- working_villages.manufacturing_data represents a table that contains manufacturing data.
-- this table's keys are product names, and values are manufacturing numbers
-- that has been already manufactured.
working_villages.manufacturing_data = (function()
  local file_name = minetest.get_worldpath() .. "/working_villages_data"

  minetest.register_on_shutdown(function()
    local file = io.open(file_name, "w")
    file:write(minetest.serialize(working_villages.manufacturing_data))
    file:close()
  end)

  local file = io.open(file_name, "r")
  if file ~= nil then
    local data = file:read("*a")
    file:close()
    return minetest.deserialize(data)
  end
  return {}
end) ()

--------------------------------------------------------------------

-- register empty item entity definition.
-- this entity may be hold by villager's hands.
do
  minetest.register_craftitem("working_villages:dummy_empty_craftitem", {
    wield_image = "working_villages_dummy_empty_craftitem.png",
  })

  local function on_activate(self)
    -- attach to the nearest villager.
    local all_objects = minetest.get_objects_inside_radius(self.object:get_pos(), 0.1)
    for _, obj in ipairs(all_objects) do
      local luaentity = obj:get_luaentity()

      if working_villages.is_villager(luaentity.name) then
        self.object:set_attach(obj, "Arm_R", {x = 0.065, y = 0.50, z = -0.15}, {x = -45, y = 0, z = 0})
        self.object:set_properties{textures={"working_villages:dummy_empty_craftitem"}}
        return
      end
    end
  end

  local function on_step(self)
    local all_objects = minetest.get_objects_inside_radius(self.object:get_pos(), 0.1)
    for _, obj in ipairs(all_objects) do
      local luaentity = obj:get_luaentity()

      if working_villages.is_villager(luaentity.name) then
        local stack = luaentity:get_wield_item_stack()

        if stack:get_name() ~= self.itemname then
          if stack:is_empty() then
            self.itemname = ""
            self.object:set_properties{textures={"working_villages:dummy_empty_craftitem"}}
          else
            self.itemname = stack:get_name()
            self.object:set_properties{textures={self.itemname}}
          end
        end
        return
      end
    end
    -- if cannot find villager, delete empty item.
    self.object:remove()
    return
  end

  minetest.register_entity("working_villages:dummy_item", {
    hp_max		    = 1,
    visual		    = "wielditem",
    visual_size	  = {x = 0.025, y = 0.025},
    collisionbox	= {0, 0, 0, 0, 0, 0},
    physical	    = false,
    textures	    = {"air"},
    on_activate	  = on_activate,
    on_step       = on_step,
    itemname      = "",
  })
end

---------------------------------------------------------------------

working_villages.job_inv = minetest.create_detached_inventory("working_villages:job_inv", {
  on_take = function(inv, listname, _, stack) --inv, listname, index, stack, player
    inv:add_item(listname,stack)
  end,
  on_put = function(inv, listname, _, stack)
    if inv:contains_item(listname, stack:peek_item(1)) then
      -- #48
      --inv:remove_item(listname, stack)
      stack:clear()
    end
  end,
})
working_villages.job_inv:set_size("main", 64)

-- working_villages.register_job registers a definition of a new job.
function working_villages.register_job(job_name, def)
  local name = cmnp(job_name)
  working_villages.registered_jobs[name] = def

  minetest.register_tool(name, {
    stack_max       = 1,
    description     = def.description,
    inventory_image = def.inventory_image,
    groups          = {not_in_creative_inventory = 1}
  })

  --local new_size = math.max(working_villages.job_inv:get_size("main"), #working_villages.registered_jobs)
  --working_villages.job_inv:set_size("main", new_size)
  --working_villages.job_inv:set_size("main", #working_villages.registered_jobs)
  working_villages.job_inv:add_item("main", ItemStack(name))
end

-- working_villages.register_egg registers a definition of a new egg.
function working_villages.register_egg(egg_name, def)
  local name = cmnp(egg_name)
  working_villages.registered_eggs[name] = def

  minetest.register_tool(name, {
    description     = def.description,
    inventory_image = def.inventory_image,
    stack_max       = 1,

    on_use = function(itemstack, user, pointed_thing)
      if pointed_thing.above ~= nil and def.product_name ~= nil then
        -- set villager's direction.
        local new_villager = minetest.add_entity(pointed_thing.above, def.product_name)
        new_villager:get_luaentity():set_yaw_by_direction(
          vector.subtract(user:get_pos(), new_villager:get_pos())
        )
        new_villager:get_luaentity().owner_name = user:get_player_name()
        new_villager:get_luaentity():update_infotext()

        itemstack:take_item()
        return itemstack
      end
      return nil
    end,
  })
end

local job_coroutines = working_villages.require("job_coroutines")
local forms = working_villages.require("forms")

-- working_villages.register_villager registers a definition of a new villager.
function working_villages.register_villager(product_name, def)
  local name = cmnp(product_name)
  working_villages.registered_villagers[name] = def

  -- initialize manufacturing number of a new villager.
  if working_villages.manufacturing_data[name] == nil then
    working_villages.manufacturing_data[name] = 0
  end

  -- create_inventory creates a new inventory, and returns it.
  local function create_inventory(self)
    self.inventory_name = self.product_name .. "_" .. tostring(self.manufacturing_number)
    local inventory = minetest.create_detached_inventory(self.inventory_name, {
      on_put = function(_, listname, _, stack) --inv, listname, index, stack, player
        if listname == "job" then
          local job_name = stack:get_name()
          local job = working_villages.registered_jobs[job_name]
          if type(job.on_start)=="function" then
            job.on_start(self)
            self.job_thread = coroutine.create(job.on_step)
          elseif type(job.jobfunc)=="function" then
            self.job_thread = coroutine.create(job.jobfunc)
          end
          self:set_displayed_action("active")
          self:set_state_info(("I started working as %s."):format(job.description))
      end
      end,
      allow_put = function(inv, listname, _, stack) --inv, listname, index, stack, player
        -- only jobs can put to a job inventory.
        if listname == "main" then
          return stack:get_count()
      elseif listname == "job" and working_villages.is_job(stack:get_name()) then
        if not inv:is_empty("job") then
          inv:remove_item("job", inv:get_list("job")[1])
        end
        return stack:get_count()
      elseif listname == "wield_item" then
        return 0
      -- TODO other lists
      end
      return 0
      end,
      on_take = function(_, listname, _, stack) --inv, listname, index, stack, player
        if listname == "job" then
          local job_name = stack:get_name()
          local job = working_villages.registered_jobs[job_name]
          self.time_counters = {}
          if job then
            if type(job.on_stop)=="function" then
              job.on_stop(self)
            elseif type(job.jobfunc)=="function" then
              self.job_thread = false
            end
          end
          self:set_state_info("I stopped working.")
          self:update_infotext()
      end
      end,

      allow_take = function(_, listname, _, stack) --inv, listname, index, stack, player
        if listname == "wield_item" then
          return 0
      end
      return stack:get_count()
      end,

      on_move = function(inv, from_list, _, to_list, to_index)
        --inv, from_list, from_index, to_list, to_index, count, player
        if to_list == "job" or from_list == "job" then
          local job_name = inv:get_stack(to_list, to_index):get_name()
          local job = working_villages.registered_jobs[job_name]

          if to_list == "job" then
            if type(job.on_start)=="function" then
              job.on_start(self)
              self.job_thread = coroutine.create(job.on_step)
            elseif type(job.jobfunc)=="function" then
              self.job_thread = coroutine.create(job.jobfunc)
            end
          elseif from_list == "job" then
            if type(job.on_stop)=="function" then
              job.on_stop(self)
            elseif type(job.jobfunc)=="function" then
              self.job_thread = false
            end
          end

          self:set_displayed_action("active")
          self:set_state_info(("I started working as %s."):format(job.description))
        end
      end,

      allow_move = function(inv, from_list, from_index, to_list, _, count)
        --inv, from_list, from_index, to_list, to_index, count, player
        if to_list == "wield_item" then
          return 0
        end

        if to_list == "main" then
          return count
        elseif to_list == "job" and working_villages.is_job(inv:get_stack(from_list, from_index):get_name()) then
          return count
        end

        return 0
      end,
    })

    inventory:set_size("main", 16)
    inventory:set_size("job",  1)
    inventory:set_size("wield_item", 1)
    -- TODO armor, clothes, upgrades

    return inventory
  end

  local function fix_pos_data(self)
    if self:has_home() then
      -- share some data from building sign
      local sign = self:get_home()
      self.pos_data.home_pos = sign:get_door()
      self.pos_data.bed_pos = sign:get_bed()
    end
    if self.village_name then
      -- TODO: share pos data from central village data
      --local village = working_villages.get_village(self.village_name)
      --if village then
        --self.pos_data = village:get_villager_pos_data(self.inventory_name)
      --end
      -- TODO need a global table of {[village_name] = village,}
      -- village needs a register_citizen() that can be called by a villager when he spawns
      -- then during his job, the burglar/courier can get his own village name,
      -- lookup his village object in the global table
      -- get the set of that village's registered villagers
      -- solve the traveling salesman problem
      -- and then we've gotta figure out some strategy so that the workers and burglars don't contend over the square in front of their chest... I'm envisioning a drop box system
      --
      -- remove this later
      return -- do semething for luacheck
    end
  end

  -- on_activate is a callback function that is called when the object is created or recreated.
  local function on_activate(self, staticdata)
    -- TODO villager lineage
   
    -- TODO it seems that we need some sort of logic for cycling through the textures
    -- select random texture, set model and size
    --if not self.base_texture then

    --    -- compatiblity with old simple mobs textures
    --    if def.textures and type(def.textures[1]) == "string" then
    --        def.textures = {def.textures}
    --    end

    --    -- backup a few base settings
    --    self.base_texture = def.textures and def.textures[random(#def.textures)]
    --end

    -- parse the staticdata, and compose a inventory.
    if staticdata == "" then
      self.product_name = name
      self.manufacturing_number = working_villages.manufacturing_data[name]
      working_villages.manufacturing_data[name] = working_villages.manufacturing_data[name] + 1
      create_inventory(self)

      -- birthday
      self.dob = minetest.get_day_count()
      self.tod = minetest.get_timeofday()
      self.day_count = minetest.get_day_count()

      -- favorite color
      self.fave_color = colors[math.random(#colors)]
      assert(self.fave_color ~= nil)

      -- randomized name
      if minetest.get_modpath("getname") then
        self.nametag = nil
        while self.nametag == nil do
	  -- TODO family names
          -- TODO get gender
          --getname.masculineName()
          --getname.feminineName()
	  self.nametag = getname.genderlessName()
	  if minetest.get_player_by_name(self.nametag) then -- don't collide with player names
	    self.nametag = nil
	  elseif minetest.get_modpath("iaspawn") then -- there's not an easy way to hook into entity creation globally
	    local mother = nil
	    local father = nil
	    if not iaspawn.register_soul(self, mother, father) then -- don't collide with player or entity names
	      self.nametag = nil
	    end
	  end
	end
	-- TODO now that we've got a "username," we can register with HB-type mods
      end

      self.aggro = aggro.default_aggro_table()

      -- attach dummy item to new villager.
      minetest.add_entity(self.object:get_pos(), "working_villages:dummy_item")
    else
      -- if static data is not empty string, this object has beed already created.
      local data = minetest.deserialize(staticdata)

      self.product_name         = data["product_name"]
      self.manufacturing_number = data["manufacturing_number"]
      self.nametag              = data["nametag"]
      self.owner_name           = data["owner_name"]
      self.pause                = data["pause"]
      self.job_data             = data["job_data"]
      self.state_info           = data["state_info"]
      self.pos_data             = data["pos_data"]
      -- personality
      self.dob                  = data["dob"]
      self.tod                  = data["tod"]
      self.day_count            = data["day_count"]
      self.fave_color           = data["fave_color"]
      self.aggro                = data["aggro"]

      local inventory = create_inventory(self)
      for list_name, list in pairs(data["inventory"]) do
        inventory:set_list(list_name, list)
      end

      fix_pos_data(self)
    end

    self:set_displayed_action("active")

    self.object:set_nametag_attributes{
      text = self.nametag
    }

    self.object:set_velocity{x = 0, y = 0, z = 0}
    self.object:set_acceleration{x = 0, y = -self.initial_properties.weight, z = 0}

    --legacy
    if type(self.pause) == "string" then
      self.pause = (self.pause == "resting")
    end

    local job = self:get_job()
    if job ~= nil then
      if type(job.on_start)=="function" then
        job.on_start(self)
        self.job_thread = coroutine.create(job.on_step)
      elseif type(job.jobfunc)=="function" then
        self.job_thread = coroutine.create(job.jobfunc)
      end
      if self.pause then
        if type(job.on_pause)=="function" then
          job.on_pause(self)
        end
        self:set_displayed_action("resting")
      end
    end
  end

  -- get_staticdata is a callback function that is called when the object is destroyed.
  local function get_staticdata(self)
    local inventory = self:get_inventory()
    local data = {
      ["product_name"]         = self.product_name,
      ["manufacturing_number"] = self.manufacturing_number,
      ["nametag"]              = self.nametag,
      ["owner_name"]           = self.owner_name,
      ["inventory"]            = {},
      ["pause"]                = self.pause,
      ["job_data"]             = self.job_data,
      ["state_info"]           = self.state_info,
      ["pos_data"]             = self.pos_data,

      ["dob"]                  = self.dob,
      ["tod"]                  = self.tod,
      ["day_count"]            = self.day_count,
      ["fave_color"]           = self.fave_color,
      ["aggro"]                = self.aggro,
    }

    -- set lists.
    for list_name, list in pairs(inventory:get_lists()) do
      data["inventory"][list_name] = {}

      for i, item in ipairs(list) do
        data["inventory"][list_name][i] = item:to_string()
      end
    end

    return minetest.serialize(data)
  end

  -- on_step is a callback function that is called every delta times.
  local function on_step(self, dtime)
    --[[ if owner didn't login, the villager does nothing.
		-- perhaps add a check for this to be used in jobfuncs etc.
		if not minetest.get_player_by_name(self.owner_name) then
			return
		end--]]

    self:handle_liquids()

    -- pickup surrounding item.
    self:pickup_item()

    if self.pause then
      return
    end
    job_coroutines.resume(self,dtime)
  end

  -- on_rightclick is a callback function that is called when a player right-click them.
  local function on_rightclick(self, clicker)
    local wielded_stack = clicker:get_wielded_item()
    if wielded_stack:get_name() == "working_villages:commanding_sceptre"
      and (self.owner_name == "working_villages:self_employed"
        or clicker:get_player_name() == self.owner_name or
        minetest.check_player_privs(clicker, "debug")) then

      forms.show_formspec(self, "working_villages:inv_gui", clicker:get_player_name())
    else
      forms.show_formspec(self, "working_villages:talking_menu", clicker:get_player_name())
    end
  end

  -- on_punch is a callback function that is called when a player punches a villager.
  local function on_punch()--self, puncher, time_from_last_punch, tool_capabilities, dir
  --TODO: aggression (add player ratings table)
  -- the whole village should coordinate
  end

  -- register a definition of a new villager.

  local villager_def = working_villages.villager:new({
    initial_properties = {
      hp_max                      = def.hp_max,
      weight                      = def.weight,
      mesh                        = def.mesh,
      textures                    = def.textures,

      --TODO: put these into working_villagers.villager
      physical                    = true,
      visual                      = "mesh",
      visual_size                 = {x = 1, y = 1},
      collisionbox                = {-0.25, 0, -0.25, 0.25, 1.75, 0.25},
      pointable                   = true,
      stepheight                  = 0.6,
      is_visible                  = true,
      makes_footstep_sound        = true,
      automatic_face_movement_dir = false,
      infotext                    = "",
      nametag                     = "",
      static_save                 = true,
    }
  })

  -- extra initial properties
  villager_def.pause                       = false
  villager_def.disp_action                 = "inactive\nNo job"
  villager_def.state                       = "job"
  villager_def.state_info                  = "I am doing nothing particular."
  villager_def.job_thread                  = false
  villager_def.product_name                = ""
  villager_def.manufacturing_number        = -1
  villager_def.owner_name                  = ""
  villager_def.time_counters               = {}
  villager_def.destination                 = vector.new(0,0,0)
  villager_def.job_data                    = {}
  villager_def.pos_data                    = {}
  villager_def.new_job                     = ""

  -- callback methods
  villager_def.on_activate                 = on_activate
  villager_def.on_step                     = on_step
  villager_def.on_rightclick               = on_rightclick
  villager_def.on_punch                    = on_punch
  villager_def.get_staticdata              = get_staticdata
  -- TODO drop inventory, bones on death

  -- storage methods
  villager_def.get_stored_table            = working_villages.get_stored_villager_table
  villager_def.set_stored_table            = working_villages.set_stored_villager_table
  villager_def.clear_cached_table          = working_villages.clear_cached_villager_table

  -- home methods
  villager_def.get_home                    = working_villages.get_home
  villager_def.has_home                    = working_villages.is_valid_home
  villager_def.set_home                    = working_villages.set_home
  villager_def.remove_home                 = working_villages.remove_home

  villager_def.is_fake_player              = true

  -- TODO optional villager/player lineage

  minetest.register_entity(name, villager_def)

  -- register villager egg.
  working_villages.register_egg(name .. "_egg", {
    description     = name .. " egg",
    inventory_image = def.egg_image,
    product_name    = name,
  })
end










-- TODO
--function working_villages.is_village(name)
--  if working_villages.registered_villager[name] then
--    return true
--  end
--  return false
--end
function working_villages.register_village(village_name, def)
  assert(type(village_name) == "string")
  assert(type(def)          == "table")

  -- TODO don't reregister village
  -- TODO getter

  local name = cmnp(product_name)
  local tbl  = "_villages"
  local vils = working_villagers.get_stored_table(tbl)
  if    vils == nil then
    vils = {}
  end

  def["product_name"] = village_name
  --def["owner_name"]   = 
  --def["pause"]        = 
  --def["state_info"]   =
  --def["pos_data"]     = 
  def["dob"]          = minetest.get_day_count()
  def["tod"]          = minetest.get_timeofday()
  --def["fave_color"]   = 
  def["aggro"]        = aggro.default_aggro_table()

  vils[name] = def
  working_villagers.set_stored_table(tbl, def)
end
