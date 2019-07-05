working_villages.register_job("working_villages:job_empty", {
	description      = "empty (working_villages)",
	inventory_image  = "default_paper.png",
	on_start         = function() end,
	on_stop          = function() end,
	on_resume        = function() end,
	on_pause         = function() end,
	on_step          = function() end,
})

-- only a recipe of the empty job is registered.
-- other job is created by writing on the empty job.
minetest.register_craft{
	output = "working_villages:job_empty",
	recipe = {
		{"default:paper", "default:obsidian"},
	},
}
