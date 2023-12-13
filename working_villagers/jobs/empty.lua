local S = minetest.get_translator("working_villages")
local trivia = working_villages.require("jobs/trivia")

working_villages.register_job("working_villages:job_empty", {
	description      = S("empty (working_villages)"),
	trivia = trivia.get_trivia({}, {trivia.og,}),
	workflow = {
		S("I do nothing. That is my function. If you see me doing something, then something has gone horribly wrong."),
	},
	inventory_image  = "default_paper.png",
	jobfunc          = function() end,
})

-- only a recipe of the empty job is registered.
-- other job is created by writing on the empty job.
minetest.register_craft{
	output = "working_villages:job_empty",
	recipe = {
		{"default:paper", "default:obsidian"},
	},
}
