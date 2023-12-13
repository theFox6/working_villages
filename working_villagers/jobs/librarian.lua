-- TODO WIP

local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local trivia = working_villages.require("jobs/trivia")

local bookshelfs = {
	names = {
		["default:bookshelf"]   = {},
	},
}

local bookkeeping_demands = {
	["default:book"] = 99,
	["default:book_written"] = 99,
}

function bookshelfs.get_book(item_name)
	-- check more priority definitions
	for key, value in pairs(bookshelfs.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function bookshelfs.is_book(item_name)
	local data = bookshelfs.get_book(item_name);
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
		local data = bookshelfs.get_book(node.name);
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
	return bookkeeping_demands[stack:get_name()] == nil
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not bookkeeping_demands[item_name] then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(bookkeeping_demands[item_name])
	--return (not inv:contains_item("wield_item", itemstack))
	return (not inv:contains_item("main", itemstack))
end

working_villages.register_job("working_villages:job_librarian", {
	description = S("librarian (working_villages)"),
	long_description = S("I look for all sorts of bookshelfs and start brute forcing the magick key."),
	trivia = trivia.get_trivia({
	}, {trivia.unfinished, trivia.meta,}),
	workflow = {
		S("Wake up"),
		S("Handle my chest"),
		S("Equip my tool"),
		S("Go to work"),
		S("Search for bookshelfs"),
		S("Go to bookshelfs"),
		S("Use/dig the bookshelfs"),
		S("Periodically look away thoughtfully"),
	},
	inventory_image  = "default_paper.png^working_villages_builder.png",
	-- TODO on_create handler to setup mana & hp
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(take_func, put_func)
		self:handle_job_pos()

		self:count_timer("librarian:search")
		self:count_timer("librarian:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("librarian:search",20) then
			self:collect_nearest_item_by_condition(bookshelfs.is_book, searching_range)
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
				self:set_displayed_action("copying some books")
				--self:go_to(destination)
				local success, ret = self:go_to(destination)
				if not success then
					assert(target ~= nil)
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable snow")
					self:delay(100)
				else
					-- TODO for book in inventory
					-- check whether a copy already exists on the shelf
					-- if not, copy the book and place it on the shelf
					-- ehh... I need to think this out some more.
					-- whence should I get the empty books and the written books
					-- where should I put the copies
					-- one copy per shelf sounds alright
					local size = vil_inv:get_size("main");
					for index = 1,size do
						local stack = vil_inv:get_stack("main", index);
						if (not stack:is_empty())
						and stack:get_name() == "default:book"
						and not_in_shelf(stack)
						then
							local chest_meta = minetest.get_meta(chest_pos);
							local chest_inv = chest_meta:get_inventory();
							local leftover = chest_inv:add_item("main", stack);
							vil_inv:set_stack("main", index, leftover);
							for _=0,10 do coroutine.yield() end --wait 10 steps
						end
					end
				end
			end
		elseif self:timer_exceeded("librarian:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.bookshelfs = bookshelfs

