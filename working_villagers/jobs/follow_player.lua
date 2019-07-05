working_villages.register_job("working_villages:job_folow_player", {
	description      = "follower (working_villages)",
	long_description = "I'll just follow you wherever you go.",
	inventory_image  = "default_paper.png^memorandum_letters.png",
	jobfunc = function(self)
		while (not self:is_active()) do
			coroutine.yield()
		end
		local position = self.object:getpos()
		local direction = vector.new(0,0,0)
		local player = self:get_nearest_player(10)
		if player~=nil then
			local player_position = player:getpos()
			direction = vector.subtract(player_position, position)
		end
		
		if direction.y > 0 and minetest.get_item_group(minetest.get_node(self.object:getpos()).name,"liquid") > 0 then
		  self:jump()
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