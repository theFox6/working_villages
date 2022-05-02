local fail = working_villages.require("failures")
local log = working_villages.require("log")
local func = working_villages.require("jobs/util")
local pathfinder = working_villages.require("pathfinder")

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
	self.object:setvelocity{x = 0, y = 0, z = 0}
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
		self:go_to(pos)
		self:pickup_item()
	end
end

local drop_range = {x = 2, y = 10, z = 2}

function working_villages.villager:dig(pos,collect_drops)
	if func.is_protected(self, pos) then return false, fail.protected end
	self.object:setvelocity{x = 0, y = 0, z = 0}
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
	if self.object:getvelocity().x==0 and self.object:getvelocity().z==0 then
		self:set_animation(working_villages.animation_frames.MINE)
	else
		self:set_animation(working_villages.animation_frames.WALK_MINE)
	end
	--turn to target
	self:set_yaw_by_direction(dist)
	--wait 15 steps
	for _=0,15 do coroutine.yield() end
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
		local itemdef = stack:get_definition()
		if itemdef.on_place then
			stack = itemdef.on_place(stack, self.object, pointed_thing)
		elseif itemdef.type=="node" then
			stack = minetest.item_place_node(stack, self.object, pointed_thing)
			--minetest.set_node(pointed_thing.above, {name = itemname})
			--minetest.place_node(pos, {name = itemname}) --Place node with the same effects that a player would cause
		end
	end
	--take item
	self:set_wield_item_stack(stack)
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
	if self.object:getvelocity().x==0 and self.object:getvelocity().z==0 then
		self:set_animation(working_villages.animation_frames.STAND)
	else
		self:set_animation(working_villages.animation_frames.WALK)
	end

	return true
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
	self.object:setvelocity{x = 0, y = 0, z = 0}
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
		local tod = minetest.get_timeofday()
		while (tod > 0.2 and tod < 0.805) do
			coroutine.yield()
			tod = minetest.get_timeofday()
		end
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
	end
end

function working_villages.villager:goto_job()
	log.action("villager %s is going home", self.inventory_name)
	if self.pos_data.job_pos==nil then
		log.warning("villager %s couldn't find his job position",self.inventory_name)
		self:set_state_info("I am going to my job position.")
		self.job_data.in_work = true;
	else
		self:set_state_info("I am going to my job position.")
		self:set_displayed_action("going to job")
		self:go_to(self.pos_data.job_pos)
		self.job_data.in_work = true;
	end
	return true
end

function working_villages.villager:handle_job_pos()
	if (not self.job_data.in_work) then
		self:goto_job()
	end
end

