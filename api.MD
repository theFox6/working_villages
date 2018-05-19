I started using the maidroid api, but by now it's a lot different.
for specific documentation look for the comments in the (api.lua)
read (jobs/util_description.MD) for more functions

To register a new job you use:
```

working_villages.register_job("[itemstring for the job item]", {
	description      = "[description for the job item]",
	inventory_image  = "[texture for the job item]",
	on_start         = [function for initializing](self),
	on_stop          = [function to stop all actions](self),
	on_resume        = [the same as on_start can be used](self),
	on_pause         = [the same as on_stop can be used](self),
	on_step          = [function for the actions we are doing every step](self, deltaTime),
})
```

for example:
```

local function is_dark(pos)
	local light_level = minetest.get_node_light(pos)
	local below_node = monetest.get_node(vector.add(pos,{x=0,y=-1,z=0}))
	if minetest.get_node(pos).name == "air" and below_node.name~="air" then
		return light_level <= 5
	else
		return false
	end
end

working_villages.register_job("working_villages:example_job", {
	description      = "working_villages job : example",
	inventory_image  = "default_paper.png^memorandum_letters.png",
	on_start         = function(self)
		self:change_direction_randomly()
		self:set_animation(working_villages.animation_frames.WALK)
	end,
	on_stop          = function(self)
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self:set_animation(working_villages.animation_frames.STAND)
	end,
	on_resume        = [same as on_start],
	on_pause         = [same as on_stop],
	on_step          = function (self, dtime)
		if self.target and self:is_near({x=self.target.x,y=self.object:getpos().y,z=self.target.z}, 2) then
			if wield_stack:get_name() ~= "default:torch" then
				self:move_main_to_wield(function (itemname) return itemname == "default:torch" end)
			end
			self:set_state("place_wield")
			self.target = nil
		end
		self.target = working_villages.func.search_surrounding(self.object:getpos(), is_dark, {x=10,y=3,z=3})
		if self.target then
			self.destination = working_villages.func.find_adjacent_clear(self.target)
			if self.destination then
				self:set_state("goto_destination")
			end
		end
	end,
})
```