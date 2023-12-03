local follower = working_villages.require("jobs/follow_player")

local follower_tools = {
	-- need a 3d armor light for the villagers
	["working_villages:commanding_sceptre"] = 1,
}
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
      coroutine.yield()
    end
    follower.step(v)
  end,
})

--return follower
