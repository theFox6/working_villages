local S      = minetest.get_translator("working_villages")
local trivia = {}

-- farming-related, food-related
trivia.bread_basket = {
	S("I'm part of the bread basket infrastructure."),
	S("I feed this nation!"),
	S("No farmers, no food."),
}

-- poop-related, other cleanup jobs
trivia.waste_management = {
	S("I clean up after the military-industrial complex."),
	S("I'm part of the pooper scooper crew!"),
	S("I cleanup your messes, I'll have you know."),
	S("Don't mess with Texas."),
}

-- fuel-related, technic, mesecons, basic_machines
trivia.power_management = {
	S("I power the military-industrial complex."),
	S("We haven't had an oil spill since the day we removed the mod!"),
}

-- builder, excavator, etc
trivia.construction = {
	S("I'm building the military-industrial complex."),
	S("I built this nation!"),
}

-- for derivatives
trivia.herb_collector = {
	S("Me and the herb collector are kinda the same."),
}

trivia.follower = {
	S("Me and the follower are kinda the same."),
}

-- Ig I didn't use these
trivia.wood_cutter = {
	S("Me and the wood cutter are kinda the same."),
}
trivia.builder = {
	S("Me and the builder are kinda the same."),
}
trivia.farmer = { -- I'm sure I derived some from this, but I can't remember which ones
	S("Me and the farmer are kinda the same."),
}
trivia.snow_clearer = {
	S("Me and the snow clearer are kinda the same."),
}

-- for WIP
trivia.unfinished = {
	S("We've got big plans!"),
	S("My job core is under development."),
	S("It's inadvisable to run my job core in a production setting or any other setting for that matter."),
	S("Your mileage may vary."),
	S("It works on my machine."),
	S("Use the source, Luke!"),
	S("If you want it that badly, then write it yourself."),
	S("It's on my TODO list."),
	S("It's on the back burner, Mr. Ramsey."),
	S("One time I masqueraded this guy's gcc binaries with a wrapper that re-#define'd `return` to intermittently segfault."),
	S("Owner and management not responsible for injury or death resulting from the use of this equipment."),
}

trivia.default = {
	S("This mod adds Villagers performing work."),
	S("The plan is to make villagers build up their own villages."),
	S("We're part of an experiment to procedurally generate organic maps for FPS platforms."),
}

-- for OG AIs
trivia.og = {
	S("My job core is among the originals, upon which the rest are based."),
	S("My job core was assigned to the first villagers when Silver Fox created the world."),
}

-- changes nodes, the builder, miners, landscaper, gardener, etc.
trivia.griefers = {
	S("I'm a griefer."),
	S("I am part of the terraforming crew."),
	S("I make heavy changes to the nodes in the area."),
}

-- for bots that read node meta data
trivia.meta = {
	S("It's actually quite easy to read a node's meta... for me, at least."),
	S("I know something you don't know."),
}

-- for bots that get resources by alternative means, such as merchants
trivia.special = {
	S("I help the village obtain more difficult items."),
	S("I get things that *don't* grow on trees... like money."),
}

-- for bots that use normal appliances
trivia.appliances = {
	S("Using an appliance? Sounds like using a chest with extra steps."),
	S("If it's hopper-compatible, then we can probably figure it out."),
	S("If it's technic-compatible, then we can probably figure it out."),
}

-- for bots that use punch-operated appliances
trivia.punchy = {
	S("If it's mesecons-compatible then we can probably figure it out."),
	S("The first rule of minetest..."),
}

-- for bots that use rightclick-operated appliances
trivia.rightclick = {
	S("My job core officially began the digital Stone Age."),
}

trivia.first_responder = {
	S("I've seen things..."),
}

-- TODO I can't find my utility function for this
trivia.insert_all = function(dst, src)
	assert(type(dst) == "table")
	assert(type(src) == "table")
	for _, elem in ipairs(src) do
		table.insert(dst, src)
	end
end

if minetest.get_modpath("drugwars") then
	trivia.insert_all(trivia.farmer, {
		S("They call me Johnny Appleweed; that's my name."),
		S("Me and Johnny Appleseed--we're kinda the same."),
		S("I go around plantin' funny stuff and things."),
		S("Downtown scorin' lots of muff'n strange."),
	})
end

trivia.get_trivia = function(factoids, groups)
	assert(type(factoids) == "table")
	trivia.insert_all(factoids, trivia.default)

	if type(groups) == "string" then
		table.insert(factoids, groups)
		return factoids -- inline support
	end

	assert(type(groups) == "table")
	-- TODO I think I've got an n-dimensional insert lying around somewhere
	for _, group in ipairs(groups) do
		trivia.insert_all(factoids, group)
	end
	return factoids -- inline support
end

return trivia
