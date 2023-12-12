local fail = working_villages.require("failures")
local log = working_villages.require("log")
local func = working_villages.require("jobs/util")
local pathfinder = working_villages.require("pathfinder")
local S = minetest.get_translator("working_villages")

--TODO: add variable precision
function working_villages.villager:go_to(pos)
	self.destination=vector.round(pos)
	if func.walkable_pos(self.destination) then
		self.destination=pathfinder.get_ground_level(vector.round(self.destination))
	end
	local val_pos = func.validate_pos(self.object:get_pos())
	self.path = pathfinder.find_path(val_pos, self.destination, self)
	self:set_timer("go_to:find_path",0) -- find path interval
	self:set_timer("go_to:change_dir",0)
	self:set_timer("go_to:give_up",0)
	if self.path == nil then
		--TODO: actually no path shouldn't be accepted
		--we'd have to check whether we can find a shorter path in the right direction
		--return false, fail.no_path
		self.path = {self.destination}
	end
	--print("the first waypiont on his path:" .. minetest.pos_to_string(self.path[1]))
	self:change_direction(self.path[1])
	self:set_animation(working_villages.animation_frames.WALK)

	while #self.path ~= 0 do
		self:count_timer("go_to:find_path")
		self:count_timer("go_to:change_dir")
		if self:timer_exceeded("go_to:find_path",100) then
			val_pos = func.validate_pos(self.object:get_pos())
			if func.walkable_pos(self.destination) then
				self.destination=pathfinder.get_ground_level(vector.round(self.destination))
			end
			local path = pathfinder.find_path(val_pos,self.destination,self)
			if path == nil then
				self:count_timer("go_to:give_up")
				if self:timer_exceeded("go_to:give_up",3) then
					print("villager can't find path to "..minetest.pos_to_string(val_pos))
					return false, fail.no_path
				end
			else
				self.path = path
			end
		end

		if self:timer_exceeded("go_to:change_dir",30) then
			self:change_direction(self.path[1])
		end

		-- follow path
		if self:is_near({x=self.path[1].x,y=self.object:get_pos().y,z=self.path[1].z}, 1) then
			table.remove(self.path, 1)

			if #self.path == 0 then -- end of path
				 --keep walking another step for good measure
				coroutine.yield()
				break
			else -- else next step, follow next path.
				self:set_timer("go_to:find_path",0)
				self:change_direction(self.path[1])
			end
		end
		-- if vilager is stopped by obstacles, the villager must jump.
		self:handle_obstacles(true)
		-- end step
		coroutine.yield()
	end
	-- stop
	self.object:set_velocity{x = 0, y = 0, z = 0}
	self.path = nil
	self:set_animation(working_villages.animation_frames.STAND)
	return true
end

function working_villages.villager:collect_nearest_item_by_condition(cond, searching_range)
	local item = self:get_nearest_item_by_condition(cond, searching_range)
	if item == nil then
		return false
	end
	local pos = item:get_pos()
	--print("collecting item at:".. minetest.pos_to_string(pos))
	local inv=self:get_inventory()
	if inv:room_for_item("main", ItemStack(item:get_luaentity().itemstring)) then
		--self:go_to(pos)
		local success, ret = self:go_to(pos)
		if not success then
			assert(pos ~= nil)
			working_villages.failed_pos_record(pos)
			self:set_displayed_action("looking at the unreachable item")
			self:delay(100)
		else
			self:pickup_item()
		end
	end
end

-- delay the async action by @step_count steps
function working_villages.villager:delay(step_count)
	for _=0,step_count do
		coroutine.yield()
	end
end

local drop_range = {x = 2, y = 10, z = 2}

function working_villages.villager:dig(pos,collect_drops)
	if func.is_protected(self, pos) then return false, fail.protected end
	self.object:set_velocity{x = 0, y = 0, z = 0}
	local dist = vector.subtract(pos, self.object:get_pos())
	if vector.length(dist) > 5 then
		self:set_animation(working_villages.animation_frames.STAND)
		return false, fail.too_far
	end
	self:set_animation(working_villages.animation_frames.MINE)
	self:set_yaw_by_direction(dist)
	for _=0,30 do coroutine.yield() end --wait 30 steps
	local destnode = minetest.get_node(pos)
	--if not minetest.dig_node(pos) then --somehow this drops the items
	-- return false, fail.dig_fail
	--end
	local def_node = minetest.registered_items[destnode.name];
	local old_meta = nil;
	if (def_node~=nil) and (def_node.after_dig_node~=nil) then
		old_meta = minetest.get_meta(pos):to_table();
	end
	minetest.remove_node(pos)
	local stacks = minetest.get_node_drops(destnode.name)
	for _, stack in ipairs(stacks) do
		local leftover = self:add_item_to_main(stack)
		if not leftover:is_empty() then
			minetest.add_item(pos, leftover)
		end
	end
	-- TODO use wield item
	if (old_meta) then
		def_node.after_dig_node(pos, destnode, old_meta, nil)
	end
	for _, callback in ipairs(minetest.registered_on_dignodes) do
		local pos_copy = {x=pos.x, y=pos.y, z=pos.z}
		local node_copy = {name=destnode.name, param1=destnode.param1, param2=destnode.param2}
		callback(pos_copy, node_copy, nil)
	end
	local sounds = minetest.registered_nodes[destnode.name]
	if sounds then
		if sounds.sounds then
			local sound = sounds.sounds.dug
			if sound then
				minetest.sound_play(sound,{object=self.object, max_hear_distance = 10})
			end
		end
	end
	self:set_animation(working_villages.animation_frames.STAND)
	if collect_drops then
		local mystacks = minetest.get_node_drops(destnode.name)
		--perhaps simplify by just checking if the found item is one of the drops
		for _, stack in ipairs(mystacks) do
			local function is_drop(n)
				local name
				if type(n) == "table" then
					name = n.name
				else
					name = n
				end
				if name == stack then
					return true
				end
				return false
			end
			self:collect_nearest_item_by_condition(is_drop,drop_range)
			-- add to inventory, when using remove_node
			--[[local leftover = self:add_item_to_main(stack)
			if not leftover:is_empty() then
				minetest.add_item(pos, leftover)
			end]]
		end
	end
	return true
end

local function is_player_at(pos)
    	local all_objects = minetest.get_objects_inside_radius(pos, 1)
    	for _, obj in ipairs(all_objects) do
      		--local luaentity = obj:get_luaentity()
		if obj:is_player() then
			return true
		end
	end
	return false
end
function working_villages.villager:place(item,pos)
	if type(pos)~="table" then
		error("no target position given")
	end
	if func.is_protected(self,pos) then return false, fail.protected end
	local dist = vector.subtract(pos, self.object:get_pos())
	if vector.length(dist) > 5 then
		return false, fail.too_far
	end
	local destnode = minetest.get_node(pos)
	if not minetest.registered_nodes[destnode.name].buildable_to then
	 return false, fail.blocked
	end
	local find_item = function(name)
		if type(item)=="string" then
			return name == working_villages.buildings.get_registered_nodename(item)
		elseif type(item)=="table" then
			return name == working_villages.buildings.get_registered_nodename(item.name)
		elseif type(item)=="function" then
			return item(name)
		else
			log.error("got %s instead of an item",item)
			error("no item to place given")
		end
	end
	local wield_stack = self:get_wield_item_stack()
	--move item to wield
	if not (find_item(wield_stack:get_name()) or self:move_main_to_wield(find_item)) then
	 return false, fail.not_in_inventory
	end
	--set animation
	if self.object:get_velocity().x==0 and self.object:get_velocity().z==0 then
		self:set_animation(working_villages.animation_frames.MINE)
	else
		self:set_animation(working_villages.animation_frames.WALK_MINE)
	end
	--turn to target
	self:set_yaw_by_direction(dist)
	--wait 15 steps
	for _=0,15 do coroutine.yield() end

	-- fix #5: check for player at position
	if is_player_at(pos) then
	  --print('position blocked issue 5')
	  if self.object:get_velocity().x==0 and self.object:get_velocity().z==0 then
		  self:set_animation(working_villages.animation_frames.STAND)
	  else
		  self:set_animation(working_villages.animation_frames.WALK)
	  end
          return false, fail.blocked
	end
	

	--get wielded item
	local stack = self:get_wield_item_stack()
	--create pointed_thing facing upward
	--TODO: support given pointed thing via function parameter
	local pointed_thing = {
		type = "node",
		above = pos,
		under = vector.add(pos, {x = 0, y = -1, z = 0}),
	}
	--TODO: try making a placer
	local itemname = stack:get_name()
	--place item
	if type(item)=="table" then
		minetest.set_node(pointed_thing.above, item)
		--minetest.place_node(pos, item) --loses param2
		stack:take_item(1)
	else
		local before_node = minetest.get_node(pos)
		local before_count = stack:get_count()
		local itemdef = stack:get_definition()
		if itemdef.on_place then
			stack = itemdef.on_place(stack, self, pointed_thing)
		elseif itemdef.type=="node" then
			stack = minetest.item_place_node(stack, self, pointed_thing)
		end
		local after_node = minetest.get_node(pos)
		-- if the node didn't change, then the callback failed
		if before_node.name == after_node.name then
			return false, fail.protected
		end
		-- if in creative mode, the callback may not reduce the stack
		if before_count == stack:get_count() then
			stack:take_item(1)
		end
	end
	--take item
	self:set_wield_item_stack(stack)
	coroutine.yield()
	--handle sounds
	local sounds = minetest.registered_nodes[itemname]
	if sounds then
		if sounds.sounds then
			local sound = sounds.sounds.place
			if sound then
				minetest.sound_play(sound,{object=self.object, max_hear_distance = 10})
			end
		end
	end
	--reset animation
	if self.object:get_velocity().x==0 and self.object:get_velocity().z==0 then
		self:set_animation(working_villages.animation_frames.STAND)
	else
		self:set_animation(working_villages.animation_frames.WALK)
	end

	return true
end

function working_villages.villager:manipulate_chest(chest_pos, take_func, put_func, data)
	if func.is_chest(chest_pos) then
		-- try to put items
		local vil_inv = self:get_inventory();

		-- from villager to chest
		if put_func then
			local size = vil_inv:get_size("main");
			for index = 1,size do
				local stack = vil_inv:get_stack("main", index);
				if (not stack:is_empty()) and (put_func(self, stack, data)) then
					local chest_meta = minetest.get_meta(chest_pos);
					local chest_inv = chest_meta:get_inventory();
					local leftover = chest_inv:add_item("main", stack);
					vil_inv:set_stack("main", index, leftover);
					for _=0,10 do coroutine.yield() end --wait 10 steps
				end
			end
		end
		-- from chest to villager
		if take_func then
			local chest_meta = minetest.get_meta(chest_pos);
			local chest_inv = chest_meta:get_inventory();
			local size = chest_inv:get_size("main");
			for index = 1,size do
				chest_meta = minetest.get_meta(chest_pos);
				chest_inv = chest_meta:get_inventory();
				local stack = chest_inv:get_stack("main", index);
				if (not stack:is_empty()) and (take_func(self, stack, data)) then
					local leftover = vil_inv:add_item("main", stack);
					chest_inv:set_stack("main", index, leftover);
					for _=0,10 do coroutine.yield() end --wait 10 steps
				end
			end
		end
	else
		log.error("Villager %s does not find chest on position %s.", self.inventory_name, minetest.pos_to_string(chest_pos))
	end
end

function working_villages.villager.wait_until_dawn()
	local daytime = minetest.get_timeofday()
	while (daytime < 0.2 or daytime > 0.805) do
		coroutine.yield()
		daytime = minetest.get_timeofday()
	end
end

function working_villages.villager:sleep()
	log.action("villager %s is laying down",self.inventory_name)
	self.object:set_velocity{x = 0, y = 0, z = 0}
	local bed_pos = vector.new(self.pos_data.bed_pos)
	local bed_top = func.find_adjacent_pos(bed_pos,
		function(p) return string.find(minetest.get_node(p).name,"_top") end)
	local bed_bottom = func.find_adjacent_pos(bed_pos,
		function(p) return string.find(minetest.get_node(p).name,"_bottom") end)
	if bed_top and bed_bottom then
		self:set_yaw_by_direction(vector.subtract(bed_bottom, bed_top))
		bed_pos = vector.divide(vector.add(bed_top,bed_bottom),2)
	else
		log.info("villager %s found no bed", self.inventory_name)
	end
	self:set_animation(working_villages.animation_frames.LAY)
	self.object:setpos(bed_pos)
	self:set_state_info("Zzzzzzz...")
	self:set_displayed_action("sleeping")

	self.wait_until_dawn()

	local pos=self.object:get_pos()
	self.object:setpos({x=pos.x,y=pos.y+0.5,z=pos.z})
	log.action("villager %s gets up", self.inventory_name)
	self:set_animation(working_villages.animation_frames.STAND)
	self:set_state_info("I'm starting into the new day.")
	self:set_displayed_action("active")
end

function working_villages.villager:goto_bed()
	if self.pos_data.home_pos==nil then
		log.action("villager %s is waiting until dawn", self.inventory_name)
		self:set_state_info("I'm waiting for dawn to come.")
		self:set_displayed_action("waiting until dawn")
		self:set_animation(working_villages.animation_frames.SIT)
		self.object:set_velocity{x = 0, y = 0, z = 0}
		self.wait_until_dawn()
		self:set_animation(working_villages.animation_frames.STAND)
		self:set_state_info("I'm starting into the new day.")
		self:set_displayed_action("active")
	else
		log.action("villager %s is going home", self.inventory_name)
		self:set_state_info("I'm going home, it's late.")
		self:set_displayed_action("going home")
		self:go_to(self.pos_data.home_pos)
		if (self.pos_data.bed_pos==nil) then
			log.warning("villager %s couldn't find his bed",self.inventory_name)
			--TODO: go home anyway
			self:set_state_info("I am going to rest soon.\nI would love to have a bed in my home though.")
			self:set_displayed_action("waiting for dusk")
			local tod = minetest.get_timeofday()
			while (tod > 0.2 and tod < 0.805) do
				coroutine.yield()
				tod = minetest.get_timeofday()
			end
			self:set_state_info("I'm waiting for dawn to come.")
			self:set_displayed_action("waiting until dawn")
			self:set_animation(working_villages.animation_frames.SIT)
			self.object:set_velocity{x = 0, y = 0, z = 0}
			self.wait_until_dawn()
		else
			log.info("villager %s bed is at: %s", self.inventory_name, minetest.pos_to_string(self.pos_data.bed_pos))
			self:set_state_info("I'm going to bed, it's late.")
			self:set_displayed_action("going to bed")
			self:go_to(self.pos_data.bed_pos)
			self:set_state_info("I am going to sleep soon.")
			self:set_displayed_action("waiting for dusk")
			local tod = minetest.get_timeofday()
			while (tod > 0.2 and tod < 0.805) do
				coroutine.yield()
				tod = minetest.get_timeofday()
			end
			self:sleep()
			self:go_to(self.pos_data.home_pos)
		end
	end
	return true
end

function working_villages.villager:handle_night()
	local tod = minetest.get_timeofday()
	if	tod < 0.2 or tod > 0.76 then
		if (self.job_data.in_work == true) then
			self.job_data.in_work = false;
		end
		self:goto_bed()
		self.job_data.manipulated_chest = false;
	end
end

function working_villages.villager:goto_job()
	log.action("villager %s is going home", self.inventory_name)
	if self.pos_data.job_pos==nil then
		log.warning("villager %s couldn't find his job position",self.inventory_name)
		self.job_data.in_work = true;
	else
		log.action("villager %s going to job position %s", self.inventory_name, minetest.pos_to_string(self.pos_data.job_pos))
		self:set_state_info("I am going to my job position.")
		self:set_displayed_action("going to job")
		--self:go_to(self.pos_data.job_pos)
		local success, ret = self:go_to(self.pos_data.job_pos)
		if not success then
			assert(self.pos_data.job_pos ~= nil)
			working_villages.failed_pos_record(self.pos_data.job_pos)
			self:set_displayed_action("looking at the unreachable job site")
			self:delay(100)
		else
			self.job_data.in_work = true;
		end
	end
	self:set_state_info("I'm working.")
	self:set_displayed_action("active")
	return true
end

function working_villages.villager:handle_chest(take_func, put_func, data)
	if (not self.job_data.manipulated_chest) then
		local chest_pos = self.pos_data.chest_pos
		if (chest_pos~=nil) then
			log.action("villager %s is handling chest at %s", self.inventory_name, minetest.pos_to_string(chest_pos))
			self:set_state_info("I am taking and puting items from/to my chest.")
			self:set_displayed_action("active")
			local chest = minetest.get_node(chest_pos);
			local dir = minetest.facedir_to_dir(chest.param2);
			local destination = vector.subtract(chest_pos, dir);
			--self:go_to(destination)
			local success, ret = self:go_to(destination)
			if not success then
				assert(destination ~= nil)
				working_villages.failed_pos_record(destination)
				self:set_displayed_action("looking at the unreachable chest")
				self:delay(100)
			else
				self:manipulate_chest(chest_pos, take_func, put_func, data);
			end
		end
		self.job_data.manipulated_chest = true;
	end
end

function working_villages.villager:handle_job_pos()
	if (not self.job_data.in_work) then
		self:goto_job()
	end
end

-- data = {
--   appliance_id  = <some_key>,
--   appliance_pos = {x=<x>, y=<y>, z=<z>}
--   ... see below
-- }
-- self.job_data.manipulated_appliance = {
--   <some_key> = true|false,
-- }
function working_villages.villager:handle_appliance(data)
	assert(data ~= nil)
	if (not self.job_data.manipulated_appliance) then
		self.job_data.manipulated_appliance = {}
	end
	local app_id = data.appliance_id
	assert(app_id ~= nil)
	local appliance_pos = data.appliance_pos
	assert(appliance_pos ~= nil)
	--if (self.job_data.manipulated_appliance[app_id]) then
	--	log.error("villager %s already handled appliance at %s", self.inventory_name, minetest.pos_to_string(appliance_pos))
	--	return
	--end
	if (appliance_pos==nil) then return end
	--log.action("villager %s is handling appliance at %s", self.inventory_name, minetest.pos_to_string(appliance_pos))
	self:set_state_info("I am taking and puting items from/to my appliance.")
	self:set_displayed_action("active")
	local appliance = minetest.get_node(appliance_pos);
	local dir = minetest.facedir_to_dir(appliance.param2);
	local destination = vector.subtract(appliance_pos, dir);
	self:go_to(destination)
	local success, ret = self:go_to(destination)
	if not success then
		assert(destination ~= nil)
		working_villages.failed_pos_record(destination)
		self:set_displayed_action("looking at the unreachable appliance")
		self:delay(100)
	else
		self:manipulate_appliance(appliance_pos, data)
		-- TODO check whether appliance is ready/inactive
		-- this logic would be job-specific
		self.job_data.manipulated_appliance[app_id] = true;
	end
end
-- data = {
--   appliance_id = <some_key>,
--   appliance_pos = {x=<x>, y=<y>, z=<z>}
--   is_appliance  = function(pos) return true end,
--   operations    = {
--     [0] = {
--       list      = "src",
--       is_put    = true,
--       put_func  = function(villager, stack, data) return true end,
--       data      = ...,
--     },
--     [1] = {
--       list      = "fuel",
--       is_put    = true,
--       put_func  = function(villager, stack, data) return true end,
--       data      = ...,
--     },
--     [2] = {
--       list      = "dst",
--       is_take   = true,
--       take_func = function(villager, stack, data) return true end,
--       data      = ...,
--     },
--   },
-- }
function working_villages.villager:manipulate_appliance(appliance_pos, data)
	assert(data ~= nil)
	assert(data.is_appliance ~= nil)
	if not data.is_appliance(appliance_pos) then
		log.error("Villager %s does not find appliance on position %s.", self.inventory_name, minetest.pos_to_string(appliance_pos))
		return
	end
	--log.error("Villager %s finds appliance on position %s.", self.inventory_name, minetest.pos_to_string(appliance_pos))

	-- try to put items
	local vil_inv     = self:get_inventory();
	local target_node = minetest.get_node(appliance_pos)
	local target_def  = minetest.registered_nodes[target_node.name]
	local placer = self

	assert(data.operations ~= nil)
	local operations = data.operations
	assert(#operations > 0)
	for _, operation in ipairs(operations) do
		assert(operation ~= nil)
		if operation.noop then
			for _=0,operation.noop do coroutine.yield() end -- some appliances take time to produce results
		else
			local app_list_name = operation.list
			assert(app_list_name ~= nil)
		if operation.is_put then -- from villager to appliance
			assert(operation.is_take == nil)
			assert(operation.put_func ~= nil)
			local size = vil_inv:get_size("main");
			for index = 1,size do
				local stack = vil_inv:get_stack("main", index);
				if (not stack:is_empty()) and (operation.put_func(self, stack, operation.data)) then
					local appliance_meta = minetest.get_meta(appliance_pos);
					local appliance_inv = appliance_meta:get_inventory();
					--if(target_def.allow_metadata_inventory_put ~= nil) and target_def.allow_metadata_inventory_put(furnace_pos, "fuel", index, stack, placer) then -- extra sanity check... I don't know why it doesn't work
					if operation.data ~= nil and operation.data.target_count ~= nil then

						local i = operation.data.target_index
						local leftover
						if appliance_inv:get_stack(app_list_name, i):is_empty() then
							--leftover = appliance_inv:set_stack(app_list_name, i, stack);
							local new_stack = stack:take_item(operation.data.target_count)
							appliance_inv:set_stack(app_list_name, i, new_stack);
		vil_inv:set_stack("main", index, stack);
							-- TODO check if success ?
							if(target_def.on_metadata_inventory_put ~= nil) then -- active furnace doesn't have this
								target_def.on_metadata_inventory_put(appliance_pos, app_list_name, index, new_stack, placer) -- index should be 0 ?
							end
						end
					else
						local leftover = appliance_inv:add_item(app_list_name, stack);
						vil_inv:set_stack("main", index, leftover);
						if(target_def.on_metadata_inventory_put ~= nil) then -- active furnace doesn't have this
							target_def.on_metadata_inventory_put(appliance_pos, app_list_name, index, stack, placer) -- index should be 0 ?
						end
					end
					--if operation.data == nil or operation.data.target_count == nil then -- TODO
					--vil_inv:set_stack("main", index, leftover);
					--end
					log.info("Villager %s moves %s from inventory to appliance's %s on position %s.", self.inventory_name, stack:get_name(), app_list_name, minetest.pos_to_string(appliance_pos))
					for _=0,10 do coroutine.yield() end --wait 10 steps
				end
			end

		else -- from appliance to villager
			assert(operation.is_take)
			assert(operation.is_put == nil)
			assert(operation.take_func ~= nil)
			local appliance_meta = minetest.get_meta(appliance_pos);
			local appliance_inv = appliance_meta:get_inventory();
			local size = appliance_inv:get_size(app_list_name);
			for index = 1,size do
				appliance_meta = minetest.get_meta(appliance_pos);
				appliance_inv = appliance_meta:get_inventory();
				local stack = appliance_inv:get_stack(app_list_name, index);
				if (not stack:is_empty()) and (operation.take_func(self, stack, operation.data)) then
					--if(target_def.allow_metadata_inventory_take ~= nil) and target_def.allow_metadata_inventory_take(furnace_pos, "fuel", index, stack, placer) then -- extra sanity check... I don't know why it doesn't work
					local leftover = vil_inv:add_item("main", stack);
					appliance_inv:set_stack(app_list_name, index, leftover);
					if(target_def.on_metadata_inventory_take ~= nil) then -- active furnace doesn't have this
						target_def.on_metadata_inventory_take(appliance_pos, app_list_name, index, stack, placer) -- index should be 0 ?
					end
					log.info("Villager %s moves %s to inventory from appliance's %s on position %s.", self.inventory_name, stack:get_name(), app_list_name, minetest.pos_to_string(appliance_pos))
					for _=0,10 do coroutine.yield() end --wait 10 steps
				end
			end
		end
		end
	end
end

function working_villages.villager:handle_furnace(furnace_pos, take_func, put_func, put_fuel, data)
	assert(furnace_pos ~= nil)
	assert(take_func   ~= nil)
	assert( put_func   ~= nil)
	assert( put_fuel   ~= nil)
	assert(data        == nil
	or     #data       == 3)
	local my_data = {
		appliance_id  = 'my_furnace',
		appliance_pos = furnace_pos,
		is_appliance  = func.is_furnace,
		operations    = {
			[1]   = {
				list      = "fuel",
				is_put    = true,
				put_func  = put_fuel,
				--data      = data[0] or nil,
			},
			[2]   = {
				list      = "src",
				is_put    = true,
				put_func  = put_func,
				--data      = data[1] or nil,
			},
			[3]   = {
				list      = "dst",
				is_take   = true,
				take_func = take_func,
				--data      = data[2] or nil
			},
		},
	}
	self:handle_appliance(my_data)
end

function working_villages.villager:handle_lockworkshop(lockworkshop_pos, take_func, put_func, put_lock, data)
	local my_data = {
		appliance_id  = 'my_lockworkshop',
		appliance_pos = lockworkshop_pos,
		is_appliance  = func.is_lockworkshop,
		operations    = {
			[1]   = {
				list      = "lock",
				is_put    = true,
				put_func  = put_lock,
				--data      = data[0] or nil,
			},
			[2]   = {
				list      = "input",
				is_put    = true,
				put_func  = put_func,
				--data      = data[1] or nil,
			},
			[3]   = {
				list      = "output",
				is_take   = true,
				take_func = take_func,
				--data      = data[2] or nil
			},
		},
	}
	self:handle_appliance(my_data)
end

function working_villages.villager:handle_fakerytable(fakerytable_pos, take_func, put_func, put_lock, data)
	local my_data = {
		appliance_id  = 'my_fakerytable',
		appliance_pos = fakerytable_pos,
		is_appliance  = func.is_fakerytable,
		operations    = {
			[1]   = {
				list      = "dye",
				is_put    = true,
				put_func  = put_lock,
				--data      = data[0] or nil,
			},
			[2]   = {
				list      = "metal",
				is_put    = true,
				put_func  = put_func,
				--data      = data[1] or nil,
			},
			[3]   = {
				list      = "dest",
				is_take   = true,
				take_func = take_func,
				--data      = data[2] or nil
			},
		},
	}
	self:handle_appliance(my_data)
end

function working_villages.villager:handle_refinery(refinery_pos, take_func, put_func, data)
	assert(refinery_pos ~= nil)
	assert(take_func   ~= nil)
	assert( put_func   ~= nil)
	assert(data        == nil
	or     #data       == 3)
	local my_data = {
		appliance_id  = 'my_refinery',
		appliance_pos = refinery_pos,
		is_appliance  = func.is_refinery,
		operations    = {
			[1]   = {
				list      = "src",
				is_put    = true,
				put_func  = put_func,
				--data      = data[1] or nil,
			},
			[2]   = {
				list      = "dst",
				is_take   = true,
				take_func = take_func,
				--data      = data[2] or nil
			},
		},
	}
	self:handle_appliance(my_data)
end

function working_villages.villager:handle_claycrafter(furnace_pos, take_func, put_func, put_fuel, data)
	assert(furnace_pos ~= nil)
	assert(take_func   ~= nil)
	assert( put_func   ~= nil)
	assert( put_fuel   ~= nil)
	assert(data        == nil
	or     #data       == 3)
	local my_data = {
		appliance_id  = 'my_claycrafter',
		appliance_pos = furnace_pos,
		is_appliance  = func.is_claycrafter,
		operations    = {
			[1]   = {
				list      = "fuel",
				is_put    = true,
				put_func  = put_fuel,
			},
			[2]   = {
				list      = "src",
				is_put    = true,
				put_func  = put_func,
			},
			[3]   = {
				list      = "dst",
				is_take   = true,
				take_func = take_func,
			},
			[4]   = {
				list      = "vessels",
				is_take   = true,
				take_func = take_func,
			},
		},
	}
	self:handle_appliance(my_data)
end

function working_villages.villager:handle_craft_table(craft_table_pos, take_func, put_func, data)
	assert(craft_table_pos     ~= nil)
	assert(take_func        ~= nil)
	assert(put_func         ~= nil)
	assert(data             == nil)
	assert(func.is_craft_table ~= nil)
	local my_data = {
		appliance_id  = 'my_craft_table',
		appliance_pos = craft_table_pos,
		is_appliance  = func.is_craft_table,
		operations    = {},
	}
	local ntarget = #recipes
	local index = 0
	for iteration=ntarget,1,-1 do
		-- TODO handle shapless, small shapes, etc.
		local list_name
		if CRAFT_TABLE_TYPE == "craft_table" then
			list_name = "craft"
		elseif CRAFT_TABLE_TYPE == "crafting_bench" then
			list_name = "rec"
		else assert(false) end
		local recipe = recipes[iteration]
		local nx     = #recipe
		--local xy     = 0
		--for x=1,3,1 do -- 3 x 3 = 9
		for x=1,nx,1 do -- 3 x 3 = 9
			local row = recipe[x]
			local ny  = #row
			--for y=1,3,1 do
			for y=1,ny,1 do
				local xy = 3*(x-1)+y
				--xy    = xy    + 1
				index = index + 1
				my_data.operations[index]   = {
					list      = list_name,
					is_put    = true,
					put_func  = put_func,
					data      = {
						iteration    = iteration,
						recipe_x     = x,
						recipe_y     = y,
						target_index = xy,
						target_count = 1,
					},
				}
			end
		end

		if CRAFT_TABLE_TYPE == "crafting_bench" then
		index = index + 1
		my_data.operations[index]   = {
			list      = "src",
			is_put    = true,
			put_func  = put_func,
			data      = {
				iteration    = iteration,
				--recipe_x     = x,
				--recipe_y     = y,
				--target_index = xy,
			},
		}
		
		index = index + 1
		my_data.operations[index]   = {
			noop = 300,
		}

		index = index + 1
		my_data.operations[index]   = {
			list      = "dst",
			is_take   = true,
			take_func = take_func,
		}

		index = index + 1
		my_data.operations[index]   = {
			list      = "rec",
			is_take   = true,
			take_func = take_func,
		}

		index = index + 1
		my_data.operations[index]   = {
			list      = "src",
			is_take   = true,
			take_func = take_func,
		}

		end
	end
	for iteration=1,#my_data.operations,1 do
		assert(my_data.operations[iteration] ~= nil)
	end
	self:handle_appliance(my_data)
end

function working_villages.villager:handle_dyemixer(dyemixer_pos, take_func, put_func, put_fuel, take_target, put_target, data)
	assert(dyemixer_pos     ~= nil)
	assert(take_func        ~= nil)
	assert(put_func         ~= nil)
	assert(put_fuel         ~= nil)
	assert(take_target      ~= nil)
	assert(put_target       ~= nil)
	assert(data             == nil)
	assert(func.is_dyemixer ~= nil)
	local my_data = {
		appliance_id  = 'my_dyemixer',
		appliance_pos = dyemixer_pos,
		is_appliance  = func.is_dyemixer,
		operations    = {},
	}
	local ntarget = self.job_data.wools.target
	      ntarget = #ntarget
	-- I've switched the indexing to and from 0- and 1-based so many times
	-- I'm pretty sure there's an off-by-one error, but the bot seems to be
	-- more-or-less functional
	for iteration=ntarget,0,-1 do
		local index = 5*(ntarget-iteration)

		my_data.operations[index+0]   = {
			list      = "input_a",
			is_put    = true,
			put_func  = put_fuel,
			data      = {
				iteration = iteration,
				ab        = 'a',
			},
		}

		my_data.operations[index+1]   = {
			list      = "input_b",
			is_put    = true,
			put_func  = put_fuel,
			data      = {
				iteration = iteration,
				ab        = 'b',
			},
		}

		my_data.operations[index+2]   = {
			list      = "output",
			is_take   = true,
			take_func = take_target,
			--data      = data[2] or nil
		}
		
		my_data.operations[index+3]   = {
			list      = "input_a",
			is_take   = true,
			take_func = take_target,
			--data      = data[2] or nil
		}
		
		my_data.operations[index+4]   = {
			list      = "input_b",
			is_take   = true,
			take_func = take_target,
			--data      = data[2] or nil
		}
	end
	local index = 5*(ntarget-0)

	my_data.operations[index+5]   = {
		list      = "input_a",
		is_put    = true,
		put_func  = put_target,
		data      = {
			iteration = 0,
			ab        = 'a',
		},
	}
	my_data.operations[index+6]   = {
		list      = "input_b",
		is_put    = true,
		put_func  = put_func,
		--data      = data[1] or nil,
	}
	my_data.operations[index+7]   = {
		list      = "output",
		is_take   = true,
		take_func = take_func,
		--data      = data[2] or nil
	}
	for iteration=0,#my_data.operations,1 do
		assert(my_data.operations[iteration] ~= nil)
	end
	self:handle_appliance(my_data)
end

function working_villages.villager:handle_recycler(furnace_pos, take_func, put_func, data)
	assert(furnace_pos ~= nil)
	assert(take_func   ~= nil)
	assert( put_func   ~= nil)
	assert(data        == nil
	or     #data       == 3)
	local my_data = {
		appliance_id  = 'my_recycler',
		appliance_pos = furnace_pos,
		is_appliance  = func.is_recycler,
		operations    = {
			[1]   = {
				list      = "input",
				is_put    = true,
				put_func  = put_func,
				--data      = data[0] or nil,
			},
			[2]   = {
				list      = "result",
				is_take   = true,
				take_func = take_func,
				--data      = data[2] or nil
			},
			[3]   = {
				list      = "input",
				is_take   = true,
				take_func = take_func,
				--data      = data[2] or nil
			},
		},
	}
	self:handle_appliance(my_data)
end

function working_villages.use_item(self, stack, target)
	-- invokes the argument stack's on_use()
	-- return Tuple[whether successful, new stack]
	assert(self   ~= nil)
	assert(stack  ~= nil)
	assert(target ~= nil)

	--local name   = stack:get_name()
	--if name == nil then return false, nil end

	--local def    = minetest.registered_items[name]
	local def = stack:get_definition()
	if def == nil then return false, nil end

	local on_use = def.on_use
	if on_use == nil then return false, nil end

	local user          = self
	local pointed_thing = {under=target, above=target, type="node",}
	local new_stack     = on_use(stack, user, pointed_thing)

	-- TODO register position failure ?
	
	for _=0,10 do coroutine.yield() end --wait 10 steps
	return true, new_stack
end

function working_villages.place_item(self, stack, target, param2)
	assert(self   ~= nil)
	assert(stack  ~= nil)
	assert(target ~= nil)

	local placer             = self
	local pointed_thing      = {under=target, above=target, type="node",}
	--[[
	-- first attempt:
	local new_stack, success = minetest.item_place(stack, placer, pointed_thing, param2)
	return new_stack, success
	]]
	local def                = stack:get_definition()
	--if def == nil then return nil, false end -- testing

	local on_place           = def.on_place
	if on_place ~= nil then
		local new_stack = on_place(stack, placer, pointed_thing, param2)
		return new_stack, true
	end

	local node       = minetest.get_node(target)
	local target_def = minetest.registered_nodes[node.name]
	--if target_def == nil then return nil, false end -- testing
	local on_rightclick = target_def.on_rightclick
	if on_rightclick ~= nil then
		local new_stack = on_rightclick(target, node, placer, stack, pointed_thing)
		return new_stack, true
	end
	assert(false) -- testing
	return nil, false
end

function working_villages.punch_node(self, stack, target)
	assert(self   ~= nil)
	assert(stack  ~= nil)
	assert(target ~= nil)

	local puncher            = self
	local pointed_thing      = {under=target, above=target, type="node",}
	local node               = minetest.get_node(target)
	--[[
	-- first attempt:
	local new_stack          = minetest.node_punch(target, node, puncher, pointed_thing)
	return true, new_stack
	]]
	--local def                = stack:get_definition()
	--if def == nil then return false, nil

	local target_def = minetest.registered_nodes[node.name]
	--if target_def == nil then return false, nil end -- testing
	local on_punch = target_def.on_punch
	if on_punch ~= nil then
		local new_stack = on_punch(target, node, puncher, pointed_thing)
		return true, new_stack
	end
	assert(false) -- testing
	return false, nil
end

function working_villages.villager:handle_beehive(furnace_pos, take_func, put_func, data)
	assert(furnace_pos ~= nil)
	assert(take_func   ~= nil)
	assert( put_func   ~= nil)
	assert(data        == nil
	or     #data       == 3)
	local my_data = {
		appliance_id  = 'my_beehive',
		appliance_pos = furnace_pos,
		is_appliance  = func.is_beehive,
		operations    = {
			--[1]   = {
			--	list      = "bees",
			--	is_put    = true,
			--	put_func  = put_func,
			--	--data      = data[0] or nil,
			--},
			[1]   = {
				list      = "honey",
				is_take   = true,
				take_func = take_func,
				--data      = data[2] or nil
			},
		},
	}
	self:handle_appliance(my_data)
end
