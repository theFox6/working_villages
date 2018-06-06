function working_villages.villager:go_to(pos)
	self.destination=vector.round(pos)
	if working_villages.func.walkable_pos(self.destination) then
		self.destination=working_villages.pathfinder.get_ground_level(vector.round(self.destination))
	end
	local val_pos = working_villages.func.validate_pos(self.object:getpos())
	self.path = working_villages.pathfinder.get_reachable(val_pos,self.destination,self)
	self:set_timer("go_to:find_path",0) -- find path interval
	self:set_timer("go_to:change_dir",0)
	self:set_timer("go_to:give_up",0)
	if self.path == nil then
		--TODO: actually no path shouldn't be accepted
		--we'd have to check whether we can find a shorter path in the right direction
		self.path = {self.destination}
	end
	--print("the first waypiont on his path:" .. minetest.pos_to_string(self.path[1]))
	self:change_direction(self.path[1])
	self:set_animation(working_villages.animation_frames.WALK)

	while #self.path ~= 0 do
		self:count_timer("go_to:find_path")
		self:count_timer("go_to:change_dir")
		if self:timer_exceeded("go_to:find_path",100) then
			val_pos = working_villages.func.validate_pos(self.object:getpos())
			local path = working_villages.pathfinder.get_reachable(val_pos,self.destination,self)
			if path == nil then
				self:count_timer("go_to:give_up")
				if self:timer_exceeded("go_to:give_up",3) then
					self.destination=vector.round(self.destination)
					if working_villages.func.walkable_pos(self.destination) then
						self.destination=working_villages.pathfinder.get_ground_level(vector.round(self.destination))
					end
					print("villager can't find path")
					--FIXME: we ought to give up at this point
				end
			else
				self.path = path
			end
		end

		if self:timer_exceeded("go_to:change_dir",30) then
			self:change_direction(self.path[1])
		end

		-- follow path
		if self:is_near({x=self.path[1].x,y=self.object:getpos().y,z=self.path[1].z}, 1) then
			table.remove(self.path, 1)

			if #self.path == 0 then -- end of path
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
	self.object:setvelocity{x = 0, y = 0, z = 0}
	self.path = nil
	self:set_animation(working_villages.animation_frames.STAND)
end

function working_villages.villager:dig(pos)
	self.object:setvelocity{x = 0, y = 0, z = 0}
	self:set_animation(working_villages.animation_frames.MINE)
	self:set_yaw_by_direction(vector.subtract(pos, self.object:getpos()))
	for _=0,30 do coroutine.yield() end --wait 30 steps
	local destnode = minetest.get_node(pos)
	minetest.remove_node(pos)
	local stacks = minetest.get_node_drops(destnode.name)
	for _, stack in ipairs(stacks) do
		local leftover = self:add_item_to_main(stack)
		minetest.add_item(pos, leftover)
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
end

function working_villages.villager:place(item,pos)
	if type(pos)~="table" then
		error("no target position given")
	end
	local pred
	if type(item)=="string" then
		pred = function (name) return name == item end
	elseif type(item)=="function" then
		pred = item
	elseif type(item)=="table" then
		pred = function (name) return name == item.name end
	else
		error("no item to place given")
	end
	local wield_stack = self:get_wield_item_stack()
	--move item to wield
	local find_item = function(name)
		if type(item)=="string" then
			return name == working_villages.buildings.get_registered_nodename(item)
		elseif type(item)=="table" then
			return name == working_villages.buildings.get_registered_nodename(item.name)
		else
			return pred(name)
		end
	end
	if find_item(wield_stack:get_name()) or self:move_main_to_wield(find_item) then
		--set animation
		if self.object:getvelocity().x==0 and self.object:getvelocity().z==0 then
			self:set_animation(working_villages.animation_frames.MINE)
		else
			self:set_animation(working_villages.animation_frames.WALK_MINE)
		end
		--turn to target
		self:set_yaw_by_direction(vector.subtract(pos, self.object:getpos()))
		--wait 15 steps
		for _=0,15 do coroutine.yield() end
		--get wielded item
		local stack = self:get_wield_item_stack()
		--create pointed_thing
		local pointed_thing = {
			type = "node",
			above = pos,
			under = vector.add(pos, {x = 0, y = -1, z = 0}),
		}
		local itemname = stack:get_name()
		--place item
		if type(item)=="table" then
			minetest.set_node(pointed_thing.above, item)
		else
			--minetest.item_place(stack, minetest.get_player_by_name(self.owner_name), pointed_thing)
			minetest.set_node(pointed_thing.above, {name = itemname})
		end
		--take item
		stack:take_item(1)
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
	else
		minetest.chat_send_player(self.owner_name,
			"villager at " .. minetest.pos_to_string(self.object:getpos()) .. "couldn't place item")
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
	minetest.log("action","a villager is laying down")
	self.object:setvelocity{x = 0, y = 0, z = 0}
	local bed_pos=self:get_home():get_bed()
	local bed_top = working_villages.func.find_adjacent_pos(bed_pos,
		function(p) return string.find(minetest.get_node(p).name,"_top") end)
	local bed_bottom = working_villages.func.find_adjacent_pos(bed_pos,
		function(p) return string.find(minetest.get_node(p).name,"_bottom") end)
	if bed_top and bed_bottom then
		self:set_yaw_by_direction(vector.subtract(bed_bottom, bed_top))
	else
		minetest.log("info","no bed found")
	end
	self:set_animation(working_villages.animation_frames.LAY)
	self.object:setpos(bed_pos)
	self.pause="sleeping"
	self:update_infotext()

	self.wait_until_dawn()

	local pos=self.object:getpos()
	self.object:setpos({x=pos.x,y=pos.y+0.5,z=pos.z})
	minetest.log("action","a villager gets up")
	self:set_animation(working_villages.animation_frames.STAND)
	self.pause="active"
	self:update_infotext()
end

function working_villages.villager:goto_bed()
	if working_villages.debug_logging then
		minetest.log("action",self.inventory_name.." is going home")
	end
	if not self:has_home() then
		self:set_animation(working_villages.animation_frames.SIT)
		self.pause="sleeping"
		self:update_infotext()
		self.wait_until_dawn()
		self:set_animation(working_villages.animation_frames.STAND)
		self.pause="active"
		self:update_infotext()
	else
		local bed_pos = self:get_home():get_bed()
		if not bed_pos then
			minetest.log("warning","villager couldn't find his bed")
			--perhaps go home
			self:set_animation(working_villages.animation_frames.SIT)
			self.wait_until_dawn()
		else
			if working_villages.debug_logging then
				minetest.log("info","his bed is at:" .. bed_pos.x .. ",".. bed_pos.y .. ",".. bed_pos.z)
			end
			self:go_to(bed_pos)
			local tod = minetest.get_timeofday()
			while (tod > 0.2 and tod < 0.805) do
				coroutine.yield()
				tod = minetest.get_timeofday()
			end
			self:sleep()
			--perhaps go back to the position we were at before going home
			self:go_to(self:get_home():get_door())
		end
	end
end
