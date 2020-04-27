local func = working_villages.require("jobs/util")
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
	description      = "builder (working_villages)",
	long_description = "I look for the nearest building marker with a started building site. "..
"There I'll help building up the building.\
If I have the materials of course. Also I'll look for building markers within a 10 block radius. "..
"And I ignore paused building sites.",
	inventory_image  = "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		self:handle_night()
		
		self:count_timer("builder:search")
		if self:timer_exceeded("builder:search",20) then
			local marker = func.search_surrounding(self.object:getpos(), find_building, searching_range)
			if marker ~= nil then
				local meta = minetest.get_meta(marker)
				local build_pos = working_villages.buildings.get_build_pos(meta)
				if meta:get_int("index") > #working_villages.buildings.get(build_pos).nodedata then
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
				local wield_stack = self:get_wield_item_stack()
				if nname:find("beds:") and nname:find("_top") then
					local inv = self:get_inventory()
					if inv:room_for_item("main", ItemStack(nname)) then
						inv:add_item("main", ItemStack(nname))
					else
						local msg = "builder at " .. minetest.pos_to_string(self.object:getpos()) ..
							" doesn't have enough inventory space"
						if self.owner_name then
							minetest.chat_send_player(self.owner_name,msg)
						else
							print(msg)
						end
						-- should later be intelligent enough to use his own or any other chest
						return co_command.pause, "waiting for inventory space"
					end
				end
				if nname=="default:torch_wall" then
					if self:has_item_in_main(function (name) return name == "default:torch" end) then
					  local inv = self:get_inventory()
					  if inv:room_for_item("main", ItemStack(nname)) then
						  self:replace_item_from_main(ItemStack("default:torch"),ItemStack(nname))
					  else
              local msg = "builder at " .. minetest.pos_to_string(self.object:getpos()) ..
                " doesn't have enough inventory space"
              if self.owner_name then
                minetest.chat_send_player(self.owner_name,msg)
              else
               print(msg)
              end
              -- should later be intelligent enough to use his own or any other chest
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
					self:go_to(destination)
					self:place(nnode,npos)
					if minetest.get_node(npos).name==nnode.name then
						meta:set_int("index",meta:get_int("index")+1)
					end
				else
					local msg = "builder at " .. minetest.pos_to_string(self.object:getpos()) .. " doesn't have " .. nname
					if self.owner_name then
						minetest.chat_send_player(self.owner_name,msg)
					else
						print(msg)
					end
					coroutine.yield(co_command.pause,"waiting for materials")
				end
			end
		end
	end,
})