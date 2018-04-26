--TODO: remove target and/or destination from to_state

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
	local mod_y
	if searching_range.h == nil then
		if searching_range.y > 3 then
			mod_y = 2
		else
			mod_y = 0
		end
	else
		mod_y = searching_range.h
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

	--controlling state
	local function walk_randomly(self)
		local CHANGE_DIRECTION_TIME_INTERVAL = 50
		if self:timer_exceeded(1,20) then
			self:count_timer(2)
			local myJob = self:get_job()
			if myJob.states.WALK_HOME and myJob.states.WALK_HOME.self_condition(self) then
				myJob.states.WALK_HOME.to_state(self)
				self.job_state=myJob.states.WALK_HOME
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
					local target = working_villages.func.search_surrounding(
						self.object:getpos(), search_state.search_condition, sprop.searching_range)
					if target ~= nil then
						local destination = find_adjacent_clear(target)
						if destination==false then
							print("failure: no adjacent walkable found")
							destination = target
						end
						local val_pos = working_villages.func.validate_pos(self.object:getpos())
						if working_villages.debug_logging then
							minetest.log("info","looking for a path from " .. minetest.pos_to_string(val_pos) ..
								" to " .. minetest.pos_to_string(destination))
						end
						local path = working_villages.pathfinder.find_path(val_pos, destination, self)
						if path == nil then
							local corr_dest = working_villages.pathfinder.get_ground_level({x=destination.x,y=destination.y-1,z=destination.z})
							if working_villages.debug_logging then
								minetest.log("info","looking for a new path from " .. minetest.pos_to_string(val_pos) ..
									" to " .. minetest.pos_to_string(corr_dest))
							end
							path = working_villages.pathfinder.find_path(val_pos, corr_dest, self)
						end
						if path ~= nil then
							--print("path found to: " .. minetest.pos_to_string(destination))
							if search_state.to_state then
								search_state.to_state(self, destination, target)
							end
							self.job_state=search_state
							return
						end
					end
				elseif search_state.target_getter ~= nil and self_cond then
					local target = search_state.target_getter(self, sprop.searching_range)
					if target ~= nil then
						local distance = vector.subtract(target, self.object:getpos())
						if distance.x<=sprop.searching_range.x
								and distance.y<=sprop.searching_range.y
								and distance.z<=sprop.searching_range.z then

							local destination = working_villages.func.validate_pos(target)
							local val_pos = working_villages.func.validate_pos(self.object:getpos())
							if working_villages.debug_logging then
								minetest.log("info","looking for a path from " .. minetest.pos_to_string(val_pos) ..
									" to " .. minetest.pos_to_string(destination))
							end
							local path = working_villages.pathfinder.find_path(val_pos, destination, self)
							if path == nil then
								local node = minetest.get_node(destination)
								local corr_dest = working_villages.pathfinder.get_ground_level({x=destination.x,y=destination.y-1,z=destination.z})
								if working_villages.debug_logging then
									minetest.log("info","looking for a new path from " .. minetest.pos_to_string(val_pos) ..
										" to " .. minetest.pos_to_string(corr_dest))
								end
								path = working_villages.pathfinder.find_path(val_pos, corr_dest, self)
							end
							if path ~= nil then
								--print("path found to: " .. minetest.pos_to_string(destination))
								if search_state.to_state then
									search_state.to_state(self, destination, target)
								end
								self.job_state=search_state
								return
							end
						end
					end
				elseif self_cond then
					if search_state.to_state then
						search_state.to_state(self)
					end
					self.job_state=search_state
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

			self:handle_obstacles()
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
						if not(destnation) then
							destination = target
						end
						local val_pos = working_villages.func.validate_pos(self.object:getpos())
						local path = working_villages.pathfinder.find_path(val_pos, destination, self)
						if path == nil then
							path = working_villages.pathfinder.find_path(val_pos, working_villages.pathfinder.get_ground_level({x=destination.x,y=destination.y-1,z=destination.z}), self)
						end
						if path ~= nil then
							if search_state.to_state then
								search_state.to_state(self, destination, target)
							end
							self.job_state=search_state
							return
						end
					end
				elseif self_cond then
					if search_state.to_state then
						search_state.to_state(self)
					end
					self.job_state=search_state
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
			self.pause="active"
			self:update_infotext()
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
		self.pause="sleeping"
		self:update_infotext()
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
		self:set_state("goto_dest")
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
					func=function() return true end,
					to_state=function(self)
						if working_villages.debug_logging then
							minetest.log("action","a villager stood up and is going outside")
						end
						self.destination=self:get_home():get_door()
						self:set_state("goto_dest")
					end,
					next_state=newStates.SEARCH}
		newStates.SLEEP         = {number=2,
					func=s_sleep,
					to_state=to_sleep,
					next_state=newStates.GO_OUT}
		newStates.WALK_HOME	= {number=3,
					func=function() return true end,
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
		self.job_state = self:get_job().states.SEARCH
		self.time_counters = {}
		self.path = nil
		self:get_job().states.SEARCH.to_state(self)
	end
	local function on_stop(self)
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self.job_state = nil
		self.time_counters = nil
		self.path = nil
		self:set_animation(working_villages.animation_frames.STAND)
	end
	local function on_resume(self)
		local job = self:get_job()
		self.object:setacceleration{x = 0, y = -10, z = 0}
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self.job_state = job.states.SEARCH
		job.states.SEARCH.to_state(self)
	end
	local function on_pause(self)
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self.job_state = nil
		self:set_animation(working_villages.animation_frames.STAND)
	end
	local function on_step(self)
		if self.job_state.next_state ~= nil then
			if self.job_state.func==nil or self.job_state.func(self) then
				self.job_state=self.job_state.next_state
				if self.job_state.to_state ~= nil then
					self.job_state.to_state(self)
				end
			end
		else
			if self.job_state.func==nil or self.job_state.func(self) then
				working_villages.func.get_back_to_searching(self)
			end
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
		self.job_state = myJob.states.SEARCH
		if myJob.states.SEARCH.to_state then
			myJob.states.SEARCH.to_state(self)
		end
	end
end