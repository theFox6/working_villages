-- PoC for using items and HB integration
-- automates the deadly process of discovering magick incantations

-- TODO mana regen
-- TODO cleaner integration with mana mod


local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")

-- limited support to two replant definitions
local spellbooks = {
	-- TODO need to check their meta
	-- TODO support more book types
	-- TODO support other magic item types
	-- TODO support engraved items
	names = {
		["default:book"]        = 1,
		["default:book_open"]   = 1,
		["default:book_closed"] = 1,
	},
}

local spellcasting_demands = {
	["iadiscordia:kallisti"] = 99,
	["iadiscordia:golden_apple"] = 99,
}

function spellbooks.get_book(item_name)
	-- check more priority definitions
	for key, value in pairs(spellbooks.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function spellbooks.is_book(item_name)
	local data = spellbooks.get_book(item_name);
	if (not data) then
		return false;
	end
	return true;
end

-- TODO support other types of magick items
local function find_book_nodes(self)
	return function(pos)
		if minetest.is_protected(pos, "") then return false end
		if working_villages.failed_pos_test(pos) then return false end

		local node = minetest.get_node(pos);
		local data = spellbooks.get_book(node.name);
		if (not data) then
			return false;
		end
		local meta  = minetest.get_meta(pos)
		local text  = meta:get_string("text")
		local owner = meta:get_string("owner")
		local title = meta:get_string("title")
		if text  == nil or text  == "" then return false end
		if owner == nil or owner == "" then return false end
		if title == nil or title == "" then return false end
		return true;
	end
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	return spellcasting_demands[stack:get_name()] == nil
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not spellcasting_demands[item_name] then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(spellcasting_demands[item_name])
	--return (not inv:contains_item("wield_item", itemstack))
	return (not inv:contains_item("main", itemstack))
end

working_villages.register_job("working_villages:job_wizard", {
	description			= "wizard (working_villages)",
	long_description = "I look for all sorts of spellbooks and start brute forcing the magick key.",
	inventory_image  = "default_paper.png^working_villages_builder.png",
	trivia = {
                "My job position was the first to use tools.",
		"My job position tests our fake player support.",
		"My job position is something only this mod can do: handle a tedious task-type that other automation mods do not.",
		"I teach kids about security models.",
		"What's the magick word? ...seriously, I'm asking.",
		"We've got big plans!",
		"theFox6 is basically the Silver Fox of this universe.",
		"`engrave` and `pencil_redo` are my inspiration.",
		"My core will be combined with a derivative of the follower's core to create combat mages with the same mana, HP mechanisms and spells as the player",
		"It's actually quite easy to read a node's meta... for me, at least.",
		"I know something you don't know.",
	},
	workflow = {
		"Wake up",
		"Handle my chest",
		"Equip my tool",
		"Go to work",
		"Search for spellbooks",
		"Go to spellbooks",
		"Use/dig the spellbooks",
		"Periodically look away thoughtfully",
	},
	-- TODO on_create handler to setup mana & hp
	jobfunc = function(self)
		self:handle_night()
		--self:handle_chest2(take_func, put_func)
		self:handle_chest(take_func, put_func)
		local stack  = self:get_wield_item_stack()
		if stack:is_empty() then
			self:move_main_to_wield(function(name)
  				return spellcasting_demands[name] ~= nil
			end)
		end
		stack  = self:get_wield_item_stack()
		if stack:is_empty() then
			self.handled_chest = false
			return
		end
		self:handle_job_pos()

		self:count_timer("wizard:search")
		self:count_timer("wizard:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("wizard:search",20) then
			self:collect_nearest_item_by_condition(spellbooks.is_book, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_book_nodes(self), searching_range)
			if target ~= nil then
				local destination = func.find_adjacent_clear(target)
				if destination then
					destination = func.find_ground_below(destination)
				end
				if destination==false then
					print("failure: no adjacent walkable found")
					destination = target
				end
				self:set_displayed_action("casting some spells")
				--self:go_to(destination)
				local success, ret = self:go_to(destination)
				if not success then
					assert(target ~= nil)
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable snow")
					self:delay(100)
				else
					self:set_displayed_action("checking for spells in book")
	--				-- TODO check HP+MP, and eat+sleep if necessary
--					local name   = stack:get_name()
--					--local def    = minetest.registered_items[name]
--					local def = stack:get_definition() -- minetest.registered_items[item_name]
--					local on_use = def.on_use
--					local user   = self
					--local playername = user.nametag
					local playername = self:get_player_name()
					assert(playername ~= nil)
					print('player name: '..playername)
					-- TODO this belongs in api
					if mana.playerlist[playername] == nil then
						mana.playerlist[playername] = {}
						mana.playerlist[playername].mana = 0
						mana.playerlist[playername].maxmana = mana.settings.default_max
						mana.playerlist[playername].regen = mana.settings.default_regen
						mana.playerlist[playername].remainder = 0
					end
					assert(mana.playerlist[playername] ~= nil)
					--SkillsFramework.append_skills(playername, {
					-- TODO this needs to be done once and probably in api
					SkillsFramework.attach_skillset(playername, {
						"iadiscordia:Chaos Magick",
					})
					-- TODO mana regen
					if mana.playerlist[playername].mana < mana.playerlist[playername].maxmana then
						self:set_displayed_action("insufficient mana: "..
						mana.playerlist[playername].mana .. " < " ..
						mana.playerlist[playername].maxmana)
						return
					end
					self:set_displayed_action("attempting spell")
--					local pointed_thing = {under=target, above=target, type="node",}
--					local new_stack = on_use(stack, user, pointed_thing)
--					self:set_wield_item_stack(new_stack)
--					-- TODO record position failure
--					for _=0,10 do coroutine.yield() end --wait 10 steps
--					-- TODO record successes so he's useful

					local flag, new_stack = working_villages.use_item(self, stack, target)
					if flag then self:set_wield_item_stack(new_stack) end
				end
			end
		elseif self:timer_exceeded("wizard:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.spellbooks = spellbooks

