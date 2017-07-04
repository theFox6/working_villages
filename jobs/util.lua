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
			local door_state = minetest.get_meta(self:get_front()):get_int("state")
			if door_state %2 == 0 then
				minetest.registered_nodes[front_node.name].on_rightclick(self:get_front(),nil,nil)
			end
		elseif minetest.registered_nodes[front_node.name].walkable and not(minetest.registered_nodes[above_node.name].walkable) then
			self.object:setvelocity{x = velocity.x, y = 6, z = velocity.z}
		end
		if not ignore_doors then
			local back_node = self:get_back_node()
			if string.find(back_node.name,"doors:door") then
				local door_state = minetest.get_meta(self:get_back()):get_int("state")
				if door_state %2 == 1 then
					minetest.registered_nodes[back_node.name].on_rightclick(self:get_back(),nil,nil)
				end
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

function working_villages.func.is_near(self, pos, distance)
	local p = self.object:getpos()
	p.y = p.y - 0.5
	return vector.distance(p, pos) < distance
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
		mod_y = 3
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
	dest_pos = vector.add(pos,{x=1,y=0,z=0})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=-1,y=0,z=0})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=0,y=1,z=0})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=0,y=-1,z=0})
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
	--basic states
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
	--controlling state
	local night_active = sprop.night_active
	local search_idle = sprop.search_idle
	local searching_range = sprop.searching_range
	local MAX_WALK_TIME = 120
	local function walk_randomly(self)
		local CHANGE_DIRECTION_TIME_INTERVAL = 50
		if self.time_counters[1] >= 20 then
			self.time_counters[1] = 0
			self.time_counters[2] = self.time_counters[2] + 1
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
					local target = working_villages.func.search_surrounding(self.object:getpos(), search_state.search_condition, searching_range)
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
				elseif self_cond then
					if search_state.to_state then
						search_state.to_state(self)
					end
					self.state=search_state
					return
				end
			end
		elseif self.time_counters[2] >= CHANGE_DIRECTION_TIME_INTERVAL then
			self.time_counters[1] = self.time_counters[1] + 1
			self.time_counters[2] = 0
			self:change_direction_randomly()
			return
		else
			self.time_counters[1] = self.time_counters[1] + 1
			self.time_counters[2] = self.time_counters[2] + 1

			working_villages.func.handle_obstacles(self,false)
			return
		end
	end

	local function to_walk_randomly(self)
		self.time_counters[1] = 20
		self.time_counters[2] = 0
		self:set_animation(working_villages.animation_frames.WALK)
	end

	local function s_search_idle(self)
		local searching_range = {x = 10, y = 10, z = 10}
		if self.time_counters[1] >= 20 then
			self.time_counters[1] = 0
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
					local target = working_villages.func.search_surrounding(self.object:getpos(), search_state.search_condition, searching_range)
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
			self.time_counters[1] = self.time_counters[1] + 1
			return
		end
	end

	local function to_search_idle(self)
		self.time_counters[1] = 0
		self.time_counters[2] = 0
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self:set_animation(working_villages.animation_frames.STAND)
	end
	
	--sleeping states
	local function s_sleep(self)
		if not(minetest.get_timeofday() < 0.2 or minetest.get_timeofday() > 0.78) then
			--pos=self.object:getpos()
			--self.object:setpos({x=pos.x,y=pos.y+0.5,z=pos.z})
			print("time to get up")
			self:set_animation(working_villages.animation_frames.STAND)
			return true
		end
		return false
	end
	local function to_sleep(self)
		--print("a villager is laying down")
		self:set_animation(working_villages.animation_frames.LAY)
		self.object:setvelocity{x = 0, y = 0, z = 0}
		local bed_pos=working_villages.home.get_bed(working_villages.homes[self.inventory_name])
		bed_pos=vector.add(bed_pos,{x=0,y=1,z=0})
		self.object:setpos(bed_pos)
		local bed_bottom = working_villages.func.find_adjacent_pos(bed_pos,function(p) return minetest.get_node(p).name=="beds:bed_bottom" end)
		if bed_bottom then
			self:set_yaw_by_direction(vector.subtract(bed_bottom, self.object:getpos()))
		end
	end
	local function follow_path(self)		
		self.time_counters[1] = self.time_counters[1] + 1
		self.time_counters[2] = self.time_counters[2] + 1
		if self.time_counters[1] >= 100 then
			self.time_counters[1] = 0
			local val_pos = working_villages.func.validate_pos(self.object:getpos())
			local path = working_villages.pathfinder.find_path(val_pos, self.destination, self)
			if path ~= nil then
				self.path = path
			end
		end

		if self.time_counters[2] >= 30 then
			self.time_counters[2] = 0
			self:change_direction(self.path[1])
		end
		
		-- follow path
		if working_villages.func.is_near(self, self.path[1], 1) then
			table.remove(self.path, 1)

			if #self.path == 0 then -- end of path
				return true
			else -- else next step, follow next path.
				self.time_counters[1] = 0
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
		self.destination=working_villages.home.get_bed(working_villages.homes[self.inventory_name])
		if working_villages.debug_logging then
			minetest.log("info","his bed is at:" .. self.destination.x .. ",".. self.destination.y .. ",".. self.destination.z)
		end
		self.destination=vector.round(self.destination)
		if working_villages.func.walkable_pos(self.destination) then
			self.destination=working_villages.pathfinder.get_ground_level(vector.round(self.destination))
		end
		local val_pos = working_villages.func.validate_pos(self.object:getpos())
		self.path = working_villages.pathfinder.find_path(val_pos, self.destination, self)
		self.time_counters[1] = 0 -- find path interval
		self.time_counters[2] = 0
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
		self.destination=working_villages.home.get_door(working_villages.homes[self.inventory_name])
		local val_pos = working_villages.func.validate_pos(self.object:getpos())
		self.path = working_villages.pathfinder.find_path(val_pos, self.destination, self)
		self.time_counters[1] = 0 -- find path interval
		self.time_counters[2] = 0
		if self.path == nil then
			self.path = {}
			self.path[1]=self.destination
		end
		self:change_direction(self.path[1])
		self:set_animation(working_villages.animation_frames.WALK)
	end
	--list all states
	local newStates={}
	if search_idle then
		newStates.SEARCH = {number=0,
				func=s_search_idle,
				to_state=to_search_idle}
	else
		newStates.SEARCH = {number=0,
				func=walk_randomly,	
				to_state=to_walk_randomly}
	end
	local i = 0
	if not(night_active) then
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
						local myHome = working_villages.homes[self.inventory_name]
						if myHome then
							if not(working_villages.home.get_bed(myHome)) then
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
		on_resume        = on_start,
		on_pause         = on_stop,
		on_step          = on_step,
		states           = newStates
	})
end