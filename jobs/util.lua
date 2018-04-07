function working_villages.func.handle_obstacles(self,ignore_fence,ignore_doors)
	local velocity = self.object:getvelocity()
	local inside_node = minetest.get_node(self.object:getpos())
	if inside_node.name == "doors:door_wood_a"
	or inside_node.name == "doors:door_glass_a"
	or inside_node.name == "doors:door_obsidian_glass_a" then
		self:change_direction(vector.round(self.object:getpos()))
	end
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
		elseif minetest.registered_nodes[front_node.name].walkable and not(minetest.registered_nodes[above_node.name].walkable) then
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

function working_villages.func.validate_pos(pos)
  local resultp = vector.round(pos)
  resultp = vector.subtract(resultp,{x=0,y=1,z=0})
  local node = minetest.get_node(resultp)
  if minetest.registered_nodes[node.name].walkable then    
    resultp = vector.subtract(pos, resultp)
    resultp = vector.round(resultp)
    resultp = vector.add(pos, resultp)
    return vector.round(resultp)
  else
    return resultp
  end
end

function working_villages.func.clear_pos(pos)
	local node=minetest.get_node(pos)
	local above_node=minetest.get_node({x=pos.x,y=pos.y+1,z=pos.z})
	return not(working_villages.pathfinder.walkable(node) or working_villages.pathfinder.walkable(above_node))
end

function working_villages.func.walkable_pos(pos)
	local node=minetest.get_node(pos)
	return working_villages.pathfinder.walkable(node)
end

function working_villages.func.find_adjacent_clear(pos)
	local found = working_villages.func.find_adjacent_pos(pos,working_villages.func.clear_pos)
	if found~=false then
		return found
	end
	found = vector.add(pos,{x=0,y=-2,z=0})
	if working_villages.func.clear_pos(found) then
		return found
	end
	return false

end

local find_adjacent_clear = working_villages.func.find_adjacent_clear

function working_villages.func.search_surrounding(pos, pred, searching_range)
	pos = vector.round(pos)
	local max_xz = math.max(searching_range.x, searching_range.z)
	local mod_y = 0
	if searching_range.y > 2 then
		mod_y = 2
	end

	for j = mod_y - searching_range.y, searching_range.y do
		local p = vector.add({x = 0, y = j, z = 0}, pos)
		if pred(p) and find_adjacent_clear(p)~=false then
			return p
		end
	end

	for i = 0, max_xz do
		for j = mod_y - searching_range.y, searching_range.y do
			for k = -i, i do
				if searching_range.x >= k and searching_range.z >= i then
					local p = vector.add({x = k, y = j, z = i}, pos)
					if pred(p) and find_adjacent_clear(p)~=false then
						return p
					end

					p = vector.add({x = k, y = j, z = -i}, pos)
					if pred(p) and find_adjacent_clear(p)~=false then
						return p
					end
				end

				if searching_range.z >= i and searching_range.z >= k then
					if i ~= k then
						local p = vector.add({x = i, y = j, z = k}, pos)
						if pred(p) and find_adjacent_clear(p)~=false then
							return p
						end
					end

					if -i ~= k then
						local p = vector.add({x = -i, y = j, z = k}, pos)
						if pred(p) and find_adjacent_clear(p)~=false then
							return p
						end
					end
				end
			end
		end
	end
	return nil
end

function working_villages.func.find_adjacent_pos(pos,pred)
	local dest_pos
	if pred(pos) then
		return pos
	end
	dest_pos = vector.add(pos,{x=0,y=1,z=0})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=0,y=-1,z=0})
		if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=1,y=0,z=0})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=-1,y=0,z=0})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=0,y=0,z=1})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=0,y=0,z=-1})
	if pred(dest_pos) then
		return dest_pos
	end
	return false
end

function working_villages.func.villager_state_machine_job(job_name,job_description,actions, sprop)
	--special properties
	if sprop.night_active ~= true then
		sprop.night_active = false
	end
	if sprop.search_idle ~= true then
		sprop.search_idle = false
	end
	if sprop.searching_range == nil or sprop.searching_range == {} then
		sprop.searching_range = {x = 10, y = 3, z = 10}
	end

	local MAX_WALK_TIME = 120

	--controlling state
	local function walk_randomly(self)
		local CHANGE_DIRECTION_TIME_INTERVAL = 50
		if self:timer_exceeded(1,20) then
			self:count_timer(2)
			local myJob = self:get_job()
			if myJob.states.WALK_HOME and myJob.states.WALK_HOME.self_condition(self) then
				myJob.states.WALK_HOME.to_state(self)
				self.state=myJob.states.WALK_HOME
				return
			end
			for _,search_state in pairs(myJob.states) do
				local self_cond = false
				if search_state.self_condition then
					if search_state.self_condition(self) then
						self_cond=true
					end
				elseif search_state.search_condition ~= nil or search_state.target_getter ~= nil then
					self_cond=true
				end
				if search_state.search_condition ~= nil and self_cond then
					local target = working_villages.func.search_surrounding(self.object:getpos(), search_state.search_condition, sprop.searching_range)
					if target ~= nil then
						local destination = find_adjacent_clear(target)
						if destination==false then
							print("failure: no adjacent walkable found")
							destination = target
						end
						local val_pos = working_villages.func.validate_pos(self.object:getpos())
						--print("looking for a path from " .. val_pos.x .. "," .. val_pos.y .. "," .. val_pos.z .. " to " .. destination.x .. "," .. destination.y .. "," .. destination.z)
						local path = working_villages.pathfinder.find_path(val_pos, destination, self)
						if path == nil then
							--print("looking for a new path from " .. val_pos.x .. "," .. val_pos.y .. "," .. val_pos.z .. " to " .. destination.x .. "," .. val_pos.y .. "," .. destination.z)
							path = working_villages.pathfinder.find_path(val_pos, working_villages.pathfinder.get_ground_level({x=destination.x,y=destination.y-1,z=destination.z}), self)
						end
						if path ~= nil then
							--print("path found to: " .. destination.x .. "," .. destination.y .. "," .. destination.z)
							if search_state.to_state then
								search_state.to_state(self, path, destination, target)
							end
							self.state=search_state
							return
						end
					end
				elseif search_state.target_getter ~= nil and self_cond then
					local target = search_state.target_getter(self, sprop.searching_range)
					if target ~= nil then
						local distance = vector.subtract(target, self.object:getpos())
						if distance.x<=sprop.searching_range.x and distance.y<=sprop.searching_range.y and distance.z<=sprop.searching_range.z then
							local destination = working_villages.func.validate_pos(target)
							local val_pos = working_villages.func.validate_pos(self.object:getpos())
							--print("looking for a path from " .. val_pos.x .. "," .. val_pos.y .. "," .. val_pos.z .. " to " .. destination.x .. "," .. destination.y .. "," .. destination.z)
							local path = working_villages.pathfinder.find_path(val_pos, destination, self)
							if path == nil then
								local node = minetest.get_node(destination)
								if minetest.registered_nodes[node.name].walkable then
									destination.y = destination.y + 1
								else
									destination.y = destination.y - 1
								end
								--print("looking for a new path from " .. val_pos.x .. "," .. val_pos.y .. "," .. val_pos.z .. " to " .. destination.x .. "," .. destination.y .. "," .. destination.z)
								path = working_villages.pathfinder.find_path(val_pos, destination, self)
							end
							if path ~= nil then
								--print("path found to: " .. destination.x .. "," .. destination.y .. "," .. destination.z)
								if search_state.to_state then
									search_state.to_state(self, path, destination, target)
								end
								self.state=search_state
								return
							end
						end
					end
				elseif self_cond then
					if search_state.to_state then
						search_state.to_state(self)
					end
					self.state=search_state
					return
				end
			end
		elseif self:timer_exceeded(2,CHANGE_DIRECTION_TIME_INTERVAL) then
			self:count_timer(1)
			self:change_direction_randomly()
			return
		else
			self:count_timer(1)
			self:count_timer(2)

			working_villages.func.handle_obstacles(self,false)
			return
		end
	end

	local function to_walk_randomly(self)
		self:set_timer(1,20)
		self:set_timer(2,0)
		self:set_animation(working_villages.animation_frames.WALK)
	end

	local function s_search_idle(self)
		if self:timer_exceeded(1,20) then
			self:set_timer(1,0)
			local myJob = self:get_job()
			for _,search_state in pairs(myJob.states) do
				local self_cond = false
				if search_state.self_condition then
					if search_state.self_condition(self) then
						self_cond=true
					end
				elseif search_state.search_condition ~= nil then
					self_cond=true
				end
				if search_state.search_condition ~= nil and self_cond then
					local target = working_villages.func.search_surrounding(self.object:getpos(), search_state.search_condition, sprop.searching_range)
					if target ~= nil then
						local destination = find_adjacent_clear(target)
						if not(destniation) then
							destination = target
						end
						local val_pos = working_villages.func.validate_pos(self.object:getpos())
						local path = working_villages.pathfinder.find_path(val_pos, destination, self)
						if path == nil then
							path = working_villages.pathfinder.find_path(val_pos, working_villages.pathfinder.get_ground_level({x=destination.x,y=destination.y-1,z=destination.z}), self)
						end
						if path ~= nil then
							if search_state.to_state then
								search_state.to_state(self, path, destination, target)
							end
							self.state=search_state
							return
						end
					end
				elseif self_cond then
					if search_state.to_state then
						search_state.to_state(self)
					end
					self.state=search_state
					return
				end
			end
		else
			self:count_timer(1)
			return
		end
	end

	local function to_search_idle(self)
		self:set_timer(1,0)
		self:set_timer(2,0)
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self:set_animation(working_villages.animation_frames.STAND)
	end
	
	--sleeping states
	local function s_sleep(self)
		if not(minetest.get_timeofday() < 0.2 or minetest.get_timeofday() > 0.76) then
			local pos=self.object:getpos()
			self.object:setpos({x=pos.x,y=pos.y+0.5,z=pos.z})
			minetest.log("action","a villager gets up")
			self:set_animation(working_villages.animation_frames.STAND)
			return true
		end
		return false
	end
	local function to_sleep(self)
		minetest.log("action","a villager is laying down")
		self.object:setvelocity{x = 0, y = 0, z = 0}
		local bed_pos=self:get_home():get_bed()
		local bed_top = working_villages.func.find_adjacent_pos(bed_pos,function(p) return string.find(minetest.get_node(p).name,"_top") end)
		local bed_bottom = working_villages.func.find_adjacent_pos(bed_pos,function(p) return string.find(minetest.get_node(p).name,"_bottom") end)
		if bed_top and bed_bottom then
			self:set_yaw_by_direction(vector.subtract(bed_bottom, bed_top))
		else
			minetest.log("info","no bed found")
		end
		self:set_animation(working_villages.animation_frames.LAY)
		self.object:setpos(vector.add(bed_pos,{x=0,y=1.5,z=0}))
	end
	local function follow_path(self)		
		self:count_timer(1)
		self:count_timer(2)
		if self:timer_exceeded(1,100) then
			local val_pos = working_villages.func.validate_pos(self.object:getpos())
			local path = working_villages.pathfinder.find_path(val_pos, self.destination, self)
			if path ~= nil then
				self.path = path
			end
		end

		if self:timer_exceeded(2,30) then
			self:change_direction(self.path[1])
		end
		
		-- follow path
		if self:is_near(self.path[1], 1) then
			table.remove(self.path, 1)

			if #self.path == 0 then -- end of path
				return true
			else -- else next step, follow next path.
				self:set_timer(1,0)
				self:change_direction(self.path[1])
			end
		else
			-- if vilager is stopped by obstacles, the villager must jump.
			working_villages.func.handle_obstacles(self,false)
		end
	end
	local function to_walk_home(self)
		if working_villages.debug_logging then		
			minetest.log("action","a villager is going home")
		end
		self.destination=self:get_home():get_bed()
		if not self.destination then
			minetest.log("warning","villager couldn't find his bed")
			return
		end
		if working_villages.debug_logging then
			minetest.log("info","his bed is at:" .. self.destination.x .. ",".. self.destination.y .. ",".. self.destination.z)
		end
		self.destination=vector.round(self.destination)
		if working_villages.func.walkable_pos(self.destination) then
			self.destination=working_villages.pathfinder.get_ground_level(vector.round(self.destination))
		end
		local val_pos = working_villages.func.validate_pos(self.object:getpos())
		self.path = working_villages.pathfinder.find_path(val_pos, self.destination, self)
		self:set_timer(1,0) -- find path interval
		self:set_timer(2,0)
		if self.path == nil then
			self.path = {}
			self.path[1]=self.destination
		end
		if working_villages.debug_logging then
			minetest.log("info","the first waypiont on his path home:" .. self.path[1].x .. ",".. self.path[1].y .. ",".. self.path[1].z)
		end
		self:change_direction(self.path[1])
		self:set_animation(working_villages.animation_frames.WALK)
	end
	local function to_go_out(self)
		if working_villages.debug_logging then		
			minetest.log("action","a villager stood up and is going outside")
		end
		self.destination=self:get_home():get_door()
		local val_pos = working_villages.func.validate_pos(self.object:getpos())
		self.path = working_villages.pathfinder.find_path(val_pos, self.destination, self)
		self:set_timer(1,0) -- find path interval
		self:set_timer(2,0)
		if self.path == nil then
			self.path = {}
			self.path[1]=self.destination
		end
		self:change_direction(self.path[1])
		self:set_animation(working_villages.animation_frames.WALK)
	end
	--list all states
	local newStates={}
	if sprop.search_idle then
		newStates.SEARCH = {number=0,
				func=s_search_idle,
				to_state=to_search_idle}
	else
		newStates.SEARCH = {number=0,
				func=walk_randomly,	
				to_state=to_walk_randomly}
	end
	local i = 0
	if not sprop.night_active then
		newStates.GO_OUT	= {number=1,
					func=follow_path,
					to_state=to_go_out,
					next_state=newStates.SEARCH}		
		newStates.SLEEP         = {number=2,
					func=s_sleep,
					to_state=to_sleep,
					next_state=newStates.GO_OUT}
		newStates.WALK_HOME	= {number=3,
					func=follow_path,
					self_condition = function (self)
						if self:has_home() then
							if not self:get_home():get_bed()  then
								return false
							end
						else
							return false
						end
						if minetest.get_timeofday() < 0.2 or minetest.get_timeofday() > 0.76 then
							return true
						else
							return false
						end
					end,
					to_state=to_walk_home,
					next_state=newStates.SLEEP}
		i = 3
	end
        for k, v in pairs(actions) do
		i = i + 1
		newStates[k] = v
		newStates[k].number = i
	end
	--job definitions
	local function on_start(self)
		self.object:setacceleration{x = 0, y = -10, z = 0}
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self.state = self:get_job().states.SEARCH
		self.time_counters = {}
		self.path = nil
		self:get_job().states.SEARCH.to_state(self)
	end
	local function on_stop(self)
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self.state = nil
		self.time_counters = nil
		self.path = nil
		self:set_animation(working_villages.animation_frames.STAND)
	end
	local function on_resume(self)
		local job = self:get_job()
		if self.state ~= job.states.SLEEP then
			job.on_start(self)
		end
	end
	local function on_pause(self)
		local job = self:get_job()
		if self.state ~= job.states.SLEEP then
			job.on_stop(self)
		end
	end
	local function on_step(self, dtime)
		if self.state.next_state ~= nil then
			if self.state.func(self) then
				self.state=self.state.next_state
				if self.state.to_state ~= nil then
					self.state.to_state(self)
				end
			end
		else
			self.state.func(self)
		end
	end
	working_villages.register_job("working_villages:"..job_name, {
		description      = "working_villages job : "..job_description,
		inventory_image  = "default_paper.png^memorandum_letters.png",
		on_start         = on_start,
		on_stop          = on_stop,
		on_resume        = on_resume,
		on_pause         = on_pause,
		on_step          = on_step,
		states           = newStates
	})
end

function working_villages.func.get_back_to_searching(self)
	local myJob = self:get_job()
	if myJob and myJob.states and myJob.states.SEARCH then
		self.state = myJob.states.SEARCH
		if myJob.states.SEARCH.to_state then
			myJob.states.SEARCH.to_state(self)
		end
	end
end