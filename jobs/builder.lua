local function is_night() return minetest.get_timeofday() < 0.2 or minetest.get_timeofday() > 0.76 end
local function find_building(p) return minetest.get_node(p).name == "working_villages:building_marker" end
local searching_range = {x = 10, y = 6, z = 10}

working_villages.register_job("working_villages:job_builder", {
	description      = "working_villages job : builder",
	inventory_image  = "default_paper.png^memorandum_letters.png",
	jobfunc = function(self)
		if is_night() then
			self:goto_bed()
		else
			self:count_timer("builder:search")
			if self:timer_exceeded("builder:search",20) then
				local marker = working_villages.func.search_surrounding(self.object:getpos(), find_building, searching_range)
				if marker ~= nil then
					local meta = minetest.get_meta(marker)
					if meta:get_string("paused") == "true" then return end
					local build_pos = working_villages.buildings.get_build_pos(meta)
					if build_pos ~= nil then
						if working_villages.buildings.get(build_pos)==nil then
							return
						end
						if meta:get_int("index") > #working_villages.buildings.get(build_pos) then
							local destination = working_villages.func.find_adjacent_clear(marker)
							if destination==false then
								print("failure: no adjacent walkable found")
								destination = marker
							end
							self:go_to(destination)
							local function is_material(name)
								return name == "working_villages:home_marker"
							end
							local wield_stack = self:get_wield_item_stack()
							if is_material(wield_stack:get_name()) or self:has_item_in_main(is_material) then
								local param2 = minetest.get_node(marker).param2
								self:dig(marker)
								self:place({name = "working_villages:home_marker", param2 = param2},marker)
								meta = minetest.get_meta(marker)
								meta:set_string("owner", self.owner_name)
							else
								local msg = "builder at " .. minetest.pos_to_string(self.object:getpos()) .. " doesn't have a home marker"
								if self.owner_name then
									minetest.chat_send_player(self.owner_name,msg)
								else
									print(msg)
								end
								self.pause = "resting"
								self.object:setvelocity{x = 0, y = 0, z = 0}
								self:set_animation(working_villages.animation_frames.STAND)
								self:update_infotext()
							end
							return
						end
						local nnode = working_villages.buildings.get(build_pos)[meta:get_int("index")]
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
								self.pause = "resting"
								self.object:setvelocity{x = 0, y = 0, z = 0}
								self:set_animation(working_villages.animation_frames.STAND)
								self:update_infotext()
								return
							end
						end
						if nname=="default:torch_wall" then
							if self:has_item_in_main(function (name) return name == "default:torch" end) then
								self:replace_item_from_main(ItemStack("default:torch"),ItemStack(nname))
							end
						end
						if is_material(wield_stack:get_name()) or self:has_item_in_main(is_material) then
							local destination = working_villages.func.find_adjacent_clear(npos)
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
							self.pause = "resting"
							self.object:setvelocity{x = 0, y = 0, z = 0}
							self:set_animation(working_villages.animation_frames.STAND)
							self:update_infotext()
						end
					end
				end
			end
		end
	end,
})