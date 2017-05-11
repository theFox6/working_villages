working_villages.register_job("working_villages:job_empty", {
	description      = "working_villages job : empty",
	inventory_image  = "default_paper.png",
	on_start         = function(self) end,
	on_stop          = function(self) end,
	on_resume        = function(self) end,
	on_pause         = function(self) end,
	on_step          = function(self, dtime) end,
})

-- only a recipe of the empty job is registered.
-- other job is created by writing on the empty job.
minetest.register_craft{
	output = "working_villages:job_empty",
	recipe = {
		{"default:paper", "default:obsidian"},
	},
}
