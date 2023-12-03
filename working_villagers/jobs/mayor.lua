local follower = working_villages.require("jobs/follow_player")
local mayor    = {}

local follower_tools = {
	-- need a 3d armor light for the villagers
	["working_villages:commanding_sceptre"] = 1,
}

function mayor.mayor_v1(v)
	self:handle_night()
	self:handle_chest(take_func, put_func)
	local stack  = self:get_wield_item_stack()
	if stack:is_empty() then
	self:move_main_to_wield(function(name)
  		return ruling_demands[name] ~= nil
	end)
	end
	self:handle_job_pos()

	local pos = self.object:get_pos()
	minetest.forceload_block(pos, true) -- TODO unload the block if we leave it

	self:count_timer("mayor:search")
	self:count_timer("mayor:change_dir")
	self:handle_obstacles()
	if self:timer_exceeded("mayor:search",20) then
		-- TODO something
	elseif self:timer_exceeded("mayor:change_dir",50) then
		-- TODO don't leave the village
		--self:change_direction_randomly()
	end
end

working_villages.register_job("working_villages:job_mayor", {
  description      = "mayor (working_villages)",
  long_description = "I keep this place running in the absence of players.",
  inventory_image  = "default_paper.png^memorandum_letters.png",
  jobfunc = function(v)
    local stack  = v:get_wield_item_stack()
    if stack:is_empty() then
        v:move_main_to_wield(function(name)
          return follower_tools[name] ~= nil
    	end)
    end
    while (v.pause) do
      --coroutine.yield()
      mayor.mayor_v1(v)
    end
    follower.step(v)
  end,
})

--return follower