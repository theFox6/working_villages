local fail = working_villages.failures

local function is_dark(pos)
	local light_level = minetest.get_node_light(pos)
	return light_level <= 5
end

working_villages.register_job("working_villages:job_torcher", {
	description      = "torcher (working_villages)",
	inventory_image  = "default_paper.png^working_villages_torcher.png",
	jobfunc = function(self)
		while (not self:is_active()) do
			coroutine.yield()
		end
		local position = self.object:getpos()
		if is_dark(position) then
			local front = self:get_front() -- if it is dark, set torch.
			if is_dark(front) then
				--FIXME: somehow the placement is wrong
				local sucess, ret = self:place("default:torch",front)
				if not sucess then
					if ret == fail.too_far then
						working_villages.log.error("placement in front of villager was too far away")
					elseif ret == fail.blocked then
						--TODO:try elsewhere
						working_villages.log.verbose("pos blocked")
					elseif ret == fail.not_in_inventory then
						local msg = "torcher at " .. minetest.pos_to_string(self.object:getpos()) .. " doesn't have torches"
						local player = self:get_nearest_player(10)
						if player ~= nil then
							minetest.chat_send_player(player:get_player_name(),msg)
						elseif self.owner_name then
							minetest.chat_send_player(self.owner_name,msg)
						else
							print(msg)
						end
						self:set_paused("in need of torches")
					else
						working_villages.log.error("unknown failure in placement " .. ret)
					end
				end
			end
		end
		local direction = vector.new(0,0,0)
		local player = self:get_nearest_player(10)
		if player~=nil then
			local player_position = player:getpos()
			direction = vector.subtract(player_position, position)
		end

		local velocity = self.object:getvelocity()
		if vector.length(direction) < 3 then
			if velocity.x~=0 or velocity.y~=0 then
				self:set_animation(working_villages.animation_frames.STAND)
				self.object:setvelocity{x = 0, y = velocity.y, z = 0}
			end
		else
			if velocity.x==0 and velocity.y==0 then
				self:set_animation(working_villages.animation_frames.WALK)
			end
			self.object:setvelocity{x = direction.x, y = velocity.y, z = direction.z}
			self:set_yaw_by_direction(direction)

			--if villager is stoped by obstacle, the villager must jump.
			self:handle_obstacles(true)
		end
	end,
})