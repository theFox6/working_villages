-- TODO it kinda works


local func = working_villages.require("jobs/util")

-- TODO I'm sure there's a way to call get_nearest_player() instead
local function get_nearest_player2(range_distance,pos)
  local min_distance = range_distance
  local player,ppos
  local position = pos

  local all_objects = minetest.get_objects_inside_radius(position, range_distance)
  for _, object in pairs(all_objects) do
    if object:is_player() then
      local player_position = object:get_pos()
      local distance = vector.distance(position, player_position)

      if distance < min_distance then
        min_distance = distance
        player = object
        ppos = player_position
      end
    end
  end
  return player,ppos,min_distance
end

local rad = 15
local function find_stone_node(self)
local function foo(pos)
	local node = minetest.get_node(pos);
  local player,player_position = self:get_nearest_player(rad,pos)
  if player == nil or player_position == nil then return false end -- don't just run off

  local stepsize = 1
  local up1 = {x=pos.x, y=pos.y+1, z=pos.z}
  local up2 = {x=pos.x, y=pos.y+2, z=pos.z}
  local can_see1, blocking_node1 = minetest.line_of_sight(player_position, up1, stepsize)
  local can_see2, blocking_node2 = minetest.line_of_sight(player_position, up2, stepsize)
  if can_see1 or can_see2 then return false end


  local position = self.object:get_pos()
  local path     = minetest.find_path(position,pos,rad,1.1,1,nil)
  return path ~= nil and #path ~= 0
end
return foo
end

--function get_keys(t)
--	assert(t ~= nil)
--  local keys={}
--  for key,_ in pairs(t) do
--    table.insert(keys, key)
--  end
--  return keys
--end
--local function find_stone_node2(self)
--local function bar(pos)
--	local node = minetest.get_node(pos);
--  local player,player_position = self:get_nearest_player(rad,pos)
--  if player ~= nil and player_position ~= nil then return true end -- don't just run off
--
--  local stepsize = 1
--  local up1 = {x=pos.x, y=pos.y+1, z=pos.z}
--  local up2 = {x=pos.x, y=pos.y+2, z=pos.z}
--  local can_see1, blocking_node1 = minetest.line_of_sight(player_position, up1, stepsize)
--  local can_see2, blocking_node2 = minetest.line_of_sight(player_position, up2, stepsize)
--  if not can_see1 or can_see2 then return true end
--
--
--  local position = self.object:get_pos()
--  local path     = minetest.find_path(position,pos,rad,1.1,1,nil)
--  return path == nil or #path == 0
--end
--	local pos       = self.object:get_pos()
--  	local minp      = {x=pos.x-rad, y=pos.y-rad, z=pos.z-rad}
--  	local maxp      = {x=pos.x+rad, y=pos.y+rad, z=pos.z+rad}
--  	local nodenames = get_keys(minetest.registered_nodes)
--  	local pos_under = minetest.find_nodes_in_area_under_air(minp, maxp, nodenames)
--	local flag      = false
--	for _, test_node in pos_under do
--		bar(test_node)
--	end
--end


local searching_range = {x = rad, y = 5, z = rad}

local mining_demands = {
}
local function put_func(_,stack)
	return mining_demands[item_name] == nil
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not mining_demands[item_name] then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(mining_demands[item_name])
	--return (not inv:contains_item("wield_item", itemstack))
	return (not inv:contains_item("main", itemstack))
end

working_villages.register_job("working_villages:job_hider", {
	description      = "hider (working_villages)",
	long_description = "I look for all sorts of rocks and collect them.",
	inventory_image  = "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		--self:handle_night()
		--self:handle_chest(take_func, put_func)
		local stack  = self:get_wield_item_stack()
		if stack:is_empty() then
		self:move_main_to_wield(function(name)
  			return mining_demands[name] ~= nil
		end)
		end
		--self:handle_job_pos()

		self:count_timer("hider:search")
		self:count_timer("hider:change_dir")
		self:handle_obstacles()
		-- TODO don't check timer if we've been found
		if self:timer_exceeded("hider:search",20) then
			local target = func.search_surrounding(self.object:get_pos(), find_stone_node(self), searching_range) -- that should fix 'em
			if target ~= nil then
				--local destination = func.find_adjacent_clear(target)
				--if destination then -- this definitely makes him burrow
				--  destination = func.find_ground_below(destination)
				--end
				--if destination==false then
				--	print("failure: no adjacent walkable found")
				--	destination = target
				--end
				local destination = target
        --local herb_data = stones.get_stone(minetest.get_node(target).name);
        --stones.get_stone(minetest.get_node(target).name);
				self:set_displayed_action("mining some rocks")
				-- We may not be able to reach the log
				local success, ret = self:go_to(destination)
				if not success then
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable rocks")
self:change_direction_randomly()
					--self:delay(100)
				else
					--success, ret = self:dig(target,true)
					--if not success then
						--working_villages.failed_pos_record(target)
						--self:set_displayed_action("confused as to why mining failed")
						--self:delay(100)
					--end
				end
			else
self:change_direction_randomly()
			end
		elseif self:timer_exceeded("hider:change_dir",50) then
			--self:change_direction_randomly()
		end
	end,
})











