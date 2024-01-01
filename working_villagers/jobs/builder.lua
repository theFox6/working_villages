local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local trivia = working_villages.require("jobs/trivia")
local co_command = working_villages.require("job_coroutines").commands

local function find_building(p)
	if minetest.get_node(p).name ~= "working_villages:building_marker" then
		return false
	end
	local meta = minetest.get_meta(p)
	if meta:get_string("state") ~= "begun" then
		return false
	end
	local build_pos = working_villages.buildings.get_build_pos(meta)
	if build_pos == nil then
		return false
	end
	if working_villages.buildings.get(build_pos)==nil then
		return false
	end
	return true
end
local searching_range = {x = 10, y = 6, z = 10}

working_villages.register_job("working_villages:job_builder", {
	description      = S("builder (working_villages)"),
	long_description = S("I look for the nearest building marker with a started building site. "..
"There I'll help building up the building.\
If I have the materials of course. Also I'll look for building markers within a 10 block radius. "..
"And I ignore paused building sites."),
	trivia = trivia.get_trivia({}, {trivia.og, trivia.construction, trivia.griefer,}),
	workflow = {
		--S("Wake up"),
		S("Handle my chest"),
		S("Equip my tool"),
		S("Go to work"),
		S("Search for bugs"),
		S("Go to bugs"),
		-- TODO handle entity-type bugs
		S("Collect (dig) bugs"),
		S("Periodically look away thoughtfully"),
	},
	inventory_image  = "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_job_pos()

		self:count_timer("builder:search")
		if self:timer_exceeded("builder:search",20) then
			local marker = func.search_surrounding(self.object:get_pos(), find_building, searching_range)
			if marker == nil then
			 self:set_state_info("I am currently looking for a building site nearby.\nHowever there wasn't one the last time I checked.")
			else
				local meta = minetest.get_meta(marker)
				local build_pos = working_villages.buildings.get_build_pos(meta)
        local building_on_pos = working_villages.buildings.get(build_pos)
				if building_on_pos.nodedata and (meta:get_int("index") > #building_on_pos.nodedata) then
				  self:set_state_info("I am currently marking a building as finished.")
					local destination = func.find_adjacent_clear(marker)
					destination = func.find_ground_below(destination)
					if destination==false then
						print("failure: no adjacent walkable found")
						destination = marker
					end
					self:go_to(destination)
					meta:set_string("state","built")
					meta:set_string("house_label", "house " .. minetest.pos_to_string(marker))
					--TODO: save beds
					meta:set_string("formspec",working_villages.buildings.get_formspec(meta))
					return
				end
				self:set_state_info("I am currently working on a building.")
				local nnode = working_villages.buildings.get(build_pos).nodedata[meta:get_int("index")]
				if nnode == nil then
					meta:set_int("index",meta:get_int("index")+1)
					return
				end
				local npos = nnode.pos
				nnode = nnode.node
				local nname = working_villages.buildings.get_registered_nodename(nnode.name)
				if nname == "air" then
					meta:set_int("index",meta:get_int("index")+1)
					return
				end
				local function is_material(name)
					return name == nname
				end
--print('nname: '..nname)
--print('index: '..meta:get_int('index'))
				local wield_stack = self:get_wield_item_stack()
				if nname:find("beds:") and nname:find("_top") then
					local inv = self:get_inventory()
					if inv:room_for_item("main", ItemStack(nname)) then
						inv:add_item("main", ItemStack(nname))
					else
						local msg = "builder at " .. minetest.pos_to_string(self.object:get_pos()) ..
							" doesn't have enough inventory space"
						if self.owner_name then
							minetest.chat_send_player(self.owner_name,msg)
						else
							print(msg)
						end
						-- should later be intelligent enough to use his own or any other chest
						self:set_state_info("I am currently waiting to get some space in my inventory.")
						return co_command.pause, "waiting for inventory space"
					end
				end
				if nname=="default:torch_wall" then
					if self:has_item_in_main(function (name) return name == "default:torch" end) then
					  local inv = self:get_inventory()
					  if inv:room_for_item("main", ItemStack(nname)) then
						  self:replace_item_from_main(ItemStack("default:torch"),ItemStack(nname))
					  else
              local msg = "builder at " .. minetest.pos_to_string(self.object:get_pos()) ..
                " doesn't have enough inventory space"
              if self.owner_name then
                minetest.chat_send_player(self.owner_name,msg)
              else
               print(msg)
              end
              -- should later be intelligent enough to use his own or any other chest
              self:set_state_info("I am currently waiting to get some space in my inventory.")
              return co_command.pause, "waiting for inventory space"
				    end
					end
				end
				if is_material(wield_stack:get_name()) or self:has_item_in_main(is_material) then
					local destination = func.find_adjacent_clear(npos)
					--FIXME: check if the ground is actually below (get_reachable)
					destination = func.find_ground_below(destination)
					if destination==false then
						print("failure: no adjacent walkable found")
						destination = npos
					end
					self:set_state_info("I am building.")
					self:go_to(destination)
					self:place(nnode,npos)
					if minetest.get_node(npos).name==nnode.name then
						meta:set_int("index",meta:get_int("index")+1)
					end
				else
					local msg = "builder at " .. minetest.pos_to_string(self.object:get_pos()) .. " doesn't have " .. nname
					if self.owner_name then
						minetest.chat_send_player(self.owner_name,msg)
					else
						print(msg)
					end
					self:set_state_info(("I am currently waiting for somebody to give me some %s."):format(nname))
					--coroutine.yield(co_command.pause,"waiting for materials")
					self.job_data.manipulated_chest = false;
					self:handle_chest(function(villager, stack)
						local item_name = stack:get_name()
						if not is_material(item_name) then return false end
						local inv = villager:get_inventory()
						local itemstack = ItemStack(item_name)
						itemstack:set_count(99)
						return (not inv:contains_item("main", itemstack))
					end, nil)
				end
			end
		end
	end,
})
