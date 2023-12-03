local func = working_villages.require("jobs/util")

local thrones = {
  -- more priority definitions
	names = {
	},
  -- less priority definitions
	groups = {
	},
}

function thrones.get_throne(item_name)
  -- check more priority definitions
	for key, value in pairs(thrones.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(thrones.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end

function thrones.is_throne(item_name)
  local data = thrones.get_throne(item_name);
  if (not data) then
    return false;
  end
  return true;
end

local function find_throne_node(pos)
	local node = minetest.get_node(pos);
  local data = thrones.get_throne(node.name);
  if (not data) then
    return false;
  end

--  if data.collect_only_top then
--    -- prevent to collect plat part, which can continue to grow
--    local pos_below = {x=pos.x, y=pos.y-1, z=pos.z}
--    local node_below = minetest.get_node(pos_below);
--    if (node_below.name~=node.name) then
--      return false;
--    end
--    local pos_above = {x=pos.x, y=pos.y+1, z=pos.z}
--    local node_above = minetest.get_node(pos_above);
--    if (node_above.name==node.name) then
--      return false;
--    end
--  end

  return true;
end

local searching_range = {x = 10, y = 5, z = 10}

local ruling_demands = {
	["working_villages:commanding_sceptre"] = 1,
}
local function put_func(_,stack)
	return ruling_demands[item_name] == nil
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not ruling_demands[item_name] then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(ruling_demands[item_name])
	--return (not inv:contains_item("wield_item", itemstack))
	return (not inv:contains_item("main", itemstack))
end

working_villages.register_job("working_villages:job_mayor", {
	description      = "mayor (working_villages)",
	long_description = "I keep the village running in the absence of players.",
	inventory_image  = "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(take_func, put_func)
		local stack  = self:get_wield_item_stack()
		if stack:is_empty() then
		self:move_main_to_wield(function(name)
  			return ruling_demands[name] ~= nil
		end)
		end
		self:handle_job_pos()

		local pos = self.object:get_pos()
		minetest.forceload_block(pos, true) -- TODO unload the block if we leave it

		self:count_timer("mayor:search")
		self:count_timer("mayor:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("mayor:search",20) then
			-- TODO something
		elseif self:timer_exceeded("mayor:change_dir",50) then
			-- TODO don't leave the village
			--self:change_direction_randomly()
		end
	end,
})

working_villages.thrones = thrones