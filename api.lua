working_villages.animation_frames = {
	STAND     = { x=  0, y= 79, },
	LAY       = { x=162, y=166, },
	WALK      = { x=168, y=187, },
	MINE      = { x=189, y=198, },
	WALK_MINE = { x=200, y=219, },
	SIT       = { x= 81, y=160, },
}

working_villages.registered_villagers = {}

working_villages.registered_jobs = {}

working_villages.registered_eggs = {}

working_villages.registered_states = {}

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

-- working_villages.villager.get_nearest_player returns a player object who
-- is the nearest to the villager.
function working_villages.villager:get_nearest_player(range_distance)
	local player, min_distance = nil, range_distance
	local position = self.object:getpos()

	local all_objects = minetest.get_objects_inside_radius(position, range_distance)
	for _, object in pairs(all_objects) do
		if object:is_player() then
			local player_position = object:getpos()
			local distance = vector.distance(position, player_position)

			if distance < min_distance then
				min_distance = distance
				player = object
			end
		end
	end
	return player
end

-- woriking_villages.villager.get_nearest_item_by_condition returns the position of
-- an item that returns true for the condition
function working_villages.villager:get_nearest_item_by_condition(cond, range_distance)
	local max_distance=range_distance
	if type(range_distance) == "table" then
		max_distance=math.max(math.max(range_distance.x,range_distance.y),range_distance.z)
	end
	local item = nil
	local min_distance = max_distance
	local position = self.object:getpos()

	local all_objects = minetest.get_objects_inside_radius(position, max_distance)
	for _, object in pairs(all_objects) do
		if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "__builtin:item" then
			local found_item = ItemStack(object:get_luaentity().itemstring):to_table()
			if found_item then
				if cond(found_item) then
					local item_position = object:getpos()
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

	return vector.add(vector.round(self.object:getpos()), direction)
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

	return vector.add(vector.round(self.object:getpos()), direction)
end

-- working_villages.villager.get_back_node returns a node that exists behind the villager.
function working_villages.villager:get_back_node()
	local back = self:get_back()
	return minetest.get_node(back)
end

-- working_villages.villager.get_look_direction returns a normalized vector that is
-- the villagers's looking direction.
function working_villages.villager:get_look_direction()
	local yaw = self.object:getyaw()
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
	self.object:setyaw(math.atan2(direction.z, direction.x) - math.pi / 2)
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
			inv:set_stack("main", i, wield_stack)
			return true
		end
	end
	return false
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
  local position = self.object:getpos()
  local direction = vector.subtract(destination, position)
	direction.y = 0
  local velocity = vector.multiply(vector.normalize(direction), 1.5)

  self.object:setvelocity(velocity)
	self:set_yaw_by_direction(direction)
end

-- working_villages.villager.change_direction_randomly change direction randonly.
function working_villages.villager:change_direction_randomly()
	local direction = {
		x = math.random(0, 5) * 2 - 5,
		y = 0,
		z = math.random(0, 5) * 2 - 5,
	}
	local velocity = vector.multiply(vector.normalize(direction), 1.5)
	self.object:setvelocity(velocity)
	self:set_yaw_by_direction(direction)
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
		minetest.log("info","timer \""..timerId.."\" was not initialized")
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
		infotext = infotext .. "this villager is inactive\nNo job\n"
	end
	infotext = infotext .. "[Owner] : " .. self.owner_name
	if self.pause=="resting" then
		infotext = infotext .. "\nthis villager is resting"
	elseif self.pause=="sleeping" then
		infotext = infotext .. "\nthis villager is sleeping"
	elseif self.pause=="active" then
		infotext = infotext .. "\nthis villager is active"
	end
	self.object:set_properties{infotext = infotext}
end

-- working_villages.villager.is_near checks if the villager is withing the radius of a position
function working_villages.villager:is_near(pos, distance)
	local p = self.object:getpos()
	p.y = p.y + 0.5
	return vector.distance(p, pos) < distance
end

--working_villages.villager.handle_obstacles(ignore_fence,ignore_doors)
--if the villager hits a walkable he wil jump
--if ignore_fence is false and the villager hits a door he opens it
--if ignore_fence is false the villager will not jump over fences
function working_villages.villager:handle_obstacles(ignore_fence,ignore_doors)
	local velocity = self.object:getvelocity()
	--local inside_node = minetest.get_node(self.object:getpos())
	--if string.find(inside_node.name,"doors:door") and not ignore_doors then
	--	self:change_direction(vector.round(self.object:getpos()))
	--end
	if velocity.y == 0 then
		local front_node = self:get_front_node()
		local above_node = self:get_front()
		above_node = vector.add(above_node,{x=0,y=1,z=0})
		above_node = minetest.get_node(above_node)
		if minetest.get_item_group(front_node.name, "fence") > 0 and not(ignore_fence) then
			self:change_direction_randomly()
		elseif string.find(front_node.name,"doors:door") and not(ignore_doors) then
			local door = doors.get(self:get_front())
			door:open()
		elseif minetest.registered_nodes[front_node.name].walkable
			and not(minetest.registered_nodes[above_node.name].walkable) then

			self.object:setvelocity{x = velocity.x, y = 6, z = velocity.z}
		end
		if not ignore_doors then
			local back_pos = self:get_back()
			if string.find(minetest.get_node(back_pos).name,"doors:door") then
				local door = doors.get(back_pos)
				door:close()
			end
		end
	end
end

-- working_villages.villager.pickup_item pickup items placed and put it to main slot.
function working_villages.villager:pickup_item()
	local pos = self.object:getpos()
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

					minetest.add_item(obj:getpos(), leftover)
					obj:get_luaentity().itemstring = ""
					obj:remove()
				end
			end
		end
	end
end

-- working_villages.villager.is_active check if the villager is paused.
function working_villages.villager:is_active()
	return self.pause == "active"
end

dofile(working_villages.modpath.."/async_actions.lua") --load states

---------------------------------------------------------------------

function working_villages.villager.get_state(id)
	return working_villages.registered_states[id]
end

function working_villages.villager:set_state(id)
	if not self.get_state(id) then
		error("state \""..id.."\" is not registered")
	end
	self.get_state(self.state).on_finish(self)
	self.state = id
	self.get_state(id).on_start(self)
end

function working_villages.register_state(id,def)
	if working_villages.registered_states[id]~=nil then
		error("state \"".. id .. "\" already registered")
	end
	if not def.on_start then def.on_start = function() end end
	if not def.on_finish then def.on_finish = function() end end
	if not def.on_step then def.on_step = function() end end
	working_villages.registered_states[id] = def
	--minetest.log("debug","registered state: "..id)
end

dofile(working_villages.modpath.."/states.lua") --load states
--TODO: move states to async_actions

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
		local all_objects = minetest.get_objects_inside_radius(self.object:getpos(), 0.1)
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
		local all_objects = minetest.get_objects_inside_radius(self.object:getpos(), 0.1)
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

-- working_villages.register_job registers a definition of a new job.
function working_villages.register_job(job_name, def)
	working_villages.registered_jobs[job_name] = def

	minetest.register_tool(job_name, {
		stack_max       = 1,
		description     = def.description,
		inventory_image = def.inventory_image,
	})
end

-- working_villages.register_egg registers a definition of a new egg.
function working_villages.register_egg(egg_name, def)
	working_villages.registered_eggs[egg_name] = def

	minetest.register_tool(egg_name, {
		description     = def.description,
		inventory_image = def.inventory_image,
		stack_max       = 1,

		on_use = function(itemstack, user, pointed_thing)
			if pointed_thing.above ~= nil and def.product_name ~= nil then
				-- set villager's direction.
				local new_villager = minetest.add_entity(pointed_thing.above, def.product_name)
				new_villager:get_luaentity():set_yaw_by_direction(
					vector.subtract(user:getpos(), new_villager:getpos())
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

-- working_villages.register_villager registers a definition of a new villager.
function working_villages.register_villager(product_name, def)
	working_villages.registered_villagers[product_name] = def

	-- initialize manufacturing number of a new villager.
	if working_villages.manufacturing_data[product_name] == nil then
		working_villages.manufacturing_data[product_name] = 0
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
					elseif type(job.jobfunc)=="function" then
						self.job_thread = coroutine.create(job.jobfunc)
					end
					self:set_state("job")
					self:update_infotext()
				end
			end,

			allow_put = function(_, listname, _, stack) --inv, listname, index, stack, player
				-- only jobs can put to a job inventory.
				if listname == "main" then
					return stack:get_count()
				elseif listname == "job" and working_villages.is_job(stack:get_name()) then
					return stack:get_count()
				elseif listname == "wield_item" then
					return 0
				end
				return 0
			end,

			on_take = function(_, listname, _, stack) --inv, listname, index, stack, player
				if listname == "job" then
					local job_name = stack:get_name()
					local job = working_villages.registered_jobs[job_name]
					self:set_state("idle")
					self.time_counters = {}
					if job then
						if type(job.on_stop)=="function" then
							job.on_stop(self)
						elseif type(job.jobfunc)=="function" then
							self.job_thread = false
						end
					end
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
						elseif type(job.jobfunc)=="function" then
							self.job_thread = coroutine.create(job.jobfunc)
						end
						self:set_state("job")
					elseif from_list == "job" then
						self:set_state("idle")
						if type(job.on_stop)=="function" then
							job.on_stop(self)
						elseif type(job.jobfunc)=="function" then
							self.job_thread = false
						end
					end

					self:update_infotext()
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

		return inventory
	end

	-- on_activate is a callback function that is called when the object is created or recreated.
	local function on_activate(self, staticdata)
		-- parse the staticdata, and compose a inventory.
		if staticdata == "" then
			self.product_name = product_name
			self.manufacturing_number = working_villages.manufacturing_data[product_name]
			working_villages.manufacturing_data[product_name] = working_villages.manufacturing_data[product_name] + 1
			create_inventory(self)

			-- attach dummy item to new villager.
			minetest.add_entity(self.object:getpos(), "working_villages:dummy_item")
		else
			-- if static data is not empty string, this object has beed already created.
			local data = minetest.deserialize(staticdata)

			self.product_name = data["product_name"]
			self.manufacturing_number = data["manufacturing_number"]
			self.nametag = data["nametag"]
			self.owner_name = data["owner_name"]
			self.pause = data["pause"]

			local inventory = create_inventory(self)
			for list_name, list in pairs(data["inventory"]) do
				inventory:set_list(list_name, list)
			end
		end

		self:update_infotext()

		self.object:set_nametag_attributes{
			text = self.nametag
		}

		self.object:setvelocity{x = 0, y = 0, z = 0}
		self.object:setacceleration{x = 0, y = -10, z = 0}

		local job = self:get_job()
		if job ~= nil then
			if type(job.on_start)=="function" then
				job.on_start(self)
			elseif type(job.jobfunc)=="function" then
				self.job_thread = coroutine.create(job.jobfunc)
			end
			self:set_state("job")
			if self.pause == "resting" then
				self:set_state("idle")
				if type(job.on_pause)=="function" then
					job.on_pause(self)
				end
			end
		end
	end

	-- get_staticdata is a callback function that is called when the object is destroyed.
	local function get_staticdata(self)
		local inventory = self:get_inventory()
		local data = {
			["product_name"] = self.product_name,
			["manufacturing_number"] = self.manufacturing_number,
			["nametag"] = self.nametag,
			["owner_name"] = self.owner_name,
			["inventory"] = {},
			["pause"] = self.pause,
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
		--upate old pause state
		if self.pause==true then
			self.pause="resting"
		elseif self.pause == false then
			self.pause="active"
		end

		-- pickup surrounding item.
		self:pickup_item()

		if self.pause ~= "active" and self.pause ~= "sleeping" then
			--TODO: get rid of self.pause
			return
		end

		if self.get_state(self.state)==nil then
			minetest.log("error", "state \""..self.state.."\" does not exist")
		end

		self.get_state(self.state).on_step(self, dtime)
	end

	-- on_rightclick is a callback function that is called when a player right-click them.
	local function on_rightclick(self, clicker)
		local wielded_stack = clicker:get_wielded_item()
		if wielded_stack:get_name() == "working_villages:commanding_sceptre"
			and clicker:get_player_name() == self.owner_name then

			working_villages.forms.show_inv_formspec(self, clicker:get_player_name())
		else
			working_villages.forms.show_talking_formspec(self, clicker:get_player_name())
		end
		self:update_infotext()
	end

	-- on_punch is a callback function that is called when a player punch then.
	local function on_punch()--self, puncher, time_from_last_punch, tool_capabilities, dir
		--TODO: aggression
	end

	-- register a definition of a new villager.
	
	local villager_def = table.copy(working_villages.villager)
	-- basic initial properties
	villager_def.hp_max               = def.hp_max
	villager_def.weight               = def.weight
	villager_def.mesh                 = def.mesh
	villager_def.textures             = def.textures

	villager_def.physical             = true
	villager_def.visual               = "mesh"
	villager_def.visual_size          = {x = 1, y = 1}
	villager_def.collisionbox         = {-0.25, 0, -0.25, 0.25, 1.75, 0.25}
	villager_def.is_visible           = true
	villager_def.makes_footstep_sound = true
	villager_def.infotext             = ""
	villager_def.nametag              = ""

	-- extra initial properties
	villager_def.pause                = "active"
	villager_def.state                = "job"
	villager_def.job_thread           = false
	villager_def.product_name         = ""
	villager_def.manufacturing_number = -1
	villager_def.owner_name           = ""
	villager_def.time_counters        = {}
	villager_def.destination          = vector.new(0,0,0)

	-- callback methods
	villager_def.on_activate          = on_activate
	villager_def.on_step              = on_step
	villager_def.on_rightclick        = on_rightclick
	villager_def.on_punch             = on_punch
	villager_def.get_staticdata       = get_staticdata

	-- home methods
	villager_def.get_home             = working_villages.get_home
	villager_def.has_home             = working_villages.is_valid_home


	minetest.register_entity(product_name, villager_def)

	-- register villager egg.
	working_villages.register_egg(product_name .. "_egg", {
		description     = product_name .. " egg",
		inventory_image = def.egg_image,
		product_name    = product_name,
	})
end
