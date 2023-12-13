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

minetest.register_craft{
	output = "building_sign:building_marker",
	recipe = {
		--{"working_villages:job_empty", "default:wall_sign_wood",},
		-- maybe other villagers can use other sorts of signs for their jobs ?
		{"working_villages:job_builder", "default:wall_sign_wood",},
		-- hmm... maybe some "job safety" warning signs could work-around some of the movement janks
		-- e.g., don't go below `y`, beware of falling nodes at `x,z`, etc.
		-- maybe secret safety info can be kept in books
		-- e.g., villagers should be aware of traps and other security measures intended to keep them safe
	},
}

