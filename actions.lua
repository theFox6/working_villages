working_villages.register_state("job",{
	on_step = function(self,dtime)
		--[[ if owner didn't login, the villager does nothing.
		if not minetest.get_player_by_name(self.owner_name) then
			return
		end--]]

		-- pickup surrounding item.
		self:pickup_item()

		-- do job method.
		local job = self:get_job()
		if (self.pause == "active" or self.pause == "sleeping") and job then
			job.on_step(self, dtime)
			--TODO: get rid of self.pause
		end
	end
})

working_villages.register_state("goto_dest",{
	on_start = function(self)
		self.destination=vector.round(self.destination)
		if working_villages.func.walkable_pos(self.destination) then
			self.destination=working_villages.pathfinder.get_ground_level(vector.round(self.destination))
		end
		local val_pos = working_villages.func.validate_pos(self.object:getpos())
		self.path = working_villages.pathfinder.find_path(val_pos, self.destination, self)
		self:set_timer("goto_dest:find_path",0) -- find path interval
		self:set_timer("goto_dest:change_dir",0)
		if self.path == nil then
			self.path = {self.destination}
		end
		--[[if working_villages.debug_logging then
			minetest.log("info","the first waypiont on his path:" .. minetest.pos_to_string(self.path[1]))
		end--]]
		self:change_direction(self.path[1])
		self:set_animation(working_villages.animation_frames.WALK)
	end,
	on_step = function(self)
		self:count_timer("goto_dest:find_path")
		self:count_timer("goto_dest:change_dir")
		if self:timer_exceeded("goto_dest:find_path",100) then
			local val_pos = working_villages.func.validate_pos(self.object:getpos())
			local path = working_villages.pathfinder.find_path(val_pos, self.destination, self)
			if path ~= nil then
				self.path = path
			end
		end

		if self:timer_exceeded("goto_dest:change_dir",30) then
			self:change_direction(self.path[1])
		end

		-- follow path
		if self:is_near(self.path[1], 1) then
			table.remove(self.path, 1)

			if #self.path == 0 then -- end of path
				self:set_state("job")
			else -- else next step, follow next path.
				self:set_timer(1,0)
				self:change_direction(self.path[1])
			end
		else
			-- if vilager is stopped by obstacles, the villager must jump.
			self:handle_obstacles()
		end
	end,
	on_finish = function(self)
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self.path = nil
		self:set_animation(working_villages.animation_frames.STAND)
	end
})