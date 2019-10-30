local fail = working_villages.require("failures")
local log = working_villages.require("log")
local co_command = working_villages.require("job_coroutines").commands

local function is_dark(pos)
	local light_level = minetest.get_node_light(pos)
	return light_level <= 5
end

working_villages.register_job("working_villages:job_torcher", {
	description      = "torcher (working_villages)",
	long_description = "I'm following the nearest player enlightning his way by placing torches.",
	inventory_image  = "default_paper.png^working_villages_torcher.png",
	jobfunc = function(self)
		while (not self:is_active()) do
			coroutine.yield()
		end
		local position = self.object:getpos()
		if is_dark(position) then
			local front = self:get_front() -- if it is dark, set torch.
			if is_dark(front) then
				--FIXME: check if a node is below to support the torch
				--perhaps check if there are nodes to the at the sides to support the torch and place to walls
				local sucess, ret = self:place("default:torch",front)
				if sucess == false then
					if ret == fail.too_far then
						log.error("torch placement in front of villager %s was too far away", self.inventory_name)
					elseif ret == fail.blocked then
						--TODO:try elsewhere
						log.verbose("pos in front of villager %s blocked", self.inventory_name)
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
						return co_command.pause,"in need of torches"
					else
						log.error("unknown failure in torch placement of villager %s: %s",self.inventory_name,ret)
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