local func = {}
local pathfinder = working_villages.require("pathfinder")

function func.find_path_toward(pos,villager)
  local dest = vector.round(pos)
  --TODO: spiral outward from pos and try to find reverse paths
  if func.walkable_pos(dest) then
    dest = pathfinder.get_ground_level(dest)
  end
  local val_pos = func.validate_pos(villager.object:get_pos())
  --FIXME: this also reverses jump height and fear height
  local _,rev = pathfinder.find_path(dest, val_pos, villager)
  return rev
end

--TODO:this is used as a workaround
-- it has to be replaced by routing
--  to the nearest possible position
function func.find_ground_below(position)
  local pos = vector.new(position)
  local height = 0
  local node
  repeat
      height = height + 1
      pos.y = pos.y - 1
      node = minetest.get_node(pos)
      if height > 10 then
        return false
      end
  until pathfinder.walkable(node)
  pos.y = pos.y + 1
  return pos
end

function func.validate_pos(pos)
  local resultp = vector.round(pos)
  local node = minetest.get_node(resultp)
  if minetest.registered_nodes[node.name].walkable then
    resultp = vector.subtract(pos, resultp)
    resultp = vector.round(resultp)
    resultp = vector.add(pos, resultp)
    return vector.round(resultp)
  else
    return resultp
  end
end

--TODO: look in pathfinder whether defining this is even nessecary
function func.clear_pos(pos)
	local node=minetest.get_node(pos)
	local above_node=minetest.get_node({x=pos.x,y=pos.y+1,z=pos.z})
	return not(pathfinder.walkable(node) or pathfinder.walkable(above_node))
end

function func.walkable_pos(pos)
	local node=minetest.get_node(pos)
	return pathfinder.walkable(node)
end

function func.find_adjacent_clear(pos)
  if not pos then error("didn't get a position") end
	local found = func.find_adjacent_pos(pos,func.clear_pos)
	if found~=false then
		return found
	end
	found = vector.add(pos,{x=0,y=-2,z=0})
	if func.clear_pos(found) then
		return found
	end
	return false

end

local find_adjacent_clear = func.find_adjacent_clear

-- search in an expanding box around pos in the XZ plane
-- first hit would be closest
local function search_surrounding(pos, pred, searching_range)
	pos = vector.round(pos)
	local max_xz = math.max(searching_range.x, searching_range.z)
	local mod_y
	if searching_range.h == nil then
		if searching_range.y > 3 then
			mod_y = 2
		else
			mod_y = 0
		end
	else
		mod_y = searching_range.h
	end

	local ret = {}

	local function check_column(dx, dz)
		if ret.pos ~= nil then return end
		for j = mod_y - searching_range.y, searching_range.y do
			local p = vector.add({x = dx, y = j, z = dz}, pos)
			if pred(p) and find_adjacent_clear(p)~=false then
				ret.pos = p
				return
			end
		end
	end

	for i = 0, max_xz do
		for k = 0, i do
			-- hit the 8 points of symmetry, bound check and skip duplicates
			if k <= searching_range.x and i <= searching_range.z then
				check_column(k, i)
				if i > 0 then
					check_column(k, -i)
				end
				if k > 0 then
					check_column(-k, i)
					if k ~= i then
						check_column(-k, -i)
					end
				end
			end

			if i <= searching_range.x and k <= searching_range.z then
				if i > 0 then
					check_column(-i, k)
				end
				if k ~= i then
					check_column(i, k)
					if k > 0 then
						check_column(-i, -k)
						check_column(i, -k)
					end
				end
			end
			if ret.pos ~= nil then
				break
			end
		end
	end
	return ret.pos
end

func.search_surrounding = search_surrounding

-- search in an expanding box around pos in the XZ plane
-- first hit would be closest
local function search_surrounding_inv(pos, pred, searching_range)
	pos = vector.round(pos)
	local max_xz = math.max(searching_range.x, searching_range.z)
	local mod_y
	if searching_range.h == nil then
		if searching_range.y > 3 then
			mod_y = 2
		else
			mod_y = 0
		end
	else
		mod_y = searching_range.h
	end

	local ret = {}

	local function check_column(dx, dz, j)
		if ret.pos ~= nil then return end
		local p = vector.add({x = dx, y = j, z = dz}, pos)
		if pred(p) and find_adjacent_clear(p)~=false then
			ret.pos = p
			return
		end
	end
	local function check_plane(j)
		for i = 0, max_xz do
			for k = 0, i do
				-- hit the 8 points of symmetry, bound check and skip duplicates
				if k <= searching_range.x and i <= searching_range.z then
					check_column(k, i, j)
					if i > 0 then
						check_column(k, -i, j)
					end
					if k > 0 then
						check_column(-k, i, j)
						if k ~= i then
							check_column(-k, -i, j)
						end
					end
				end

				if i <= searching_range.x and k <= searching_range.z then
					if i > 0 then
						check_column(-i, k, j)
					end
					if k ~= i then
						check_column(i, k, j)
						if k > 0 then
							check_column(-i, -k, j)
							check_column(i, -k, j)
						end
					end
				end

				if ret.pos ~= nil then
					break
				end
			end
		end
	end

	--for j = mod_y - searching_range.y, searching_range.y do
	for j = searching_range.y, mod_y - searching_range.y, -1 do
		check_plane(j)
		if ret.pos ~= nil then
			break
		end
	end
	return ret.pos
end
func.search_surrounding_inv = search_surrounding_inv

function func.find_adjacent_pos(pos,pred)
	local dest_pos
	if pred(pos) then
		return pos
	end
	dest_pos = vector.add(pos,{x=0,y=1,z=0})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=0,y=-1,z=0})
		if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=1,y=0,z=0})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=-1,y=0,z=0})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=0,y=0,z=1})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=0,y=0,z=-1})
	if pred(dest_pos) then
		return dest_pos
	end
	return false
end

-- Activating owner griefing settings departs from the documented behavior
-- of the protection system, and may break some protection mods.
local owner_griefing = minetest.settings:get(
    "working_villages_owner_protection")
local owner_griefing_lc = owner_griefing and string.lower(owner_griefing)

if not owner_griefing or owner_griefing_lc == "false" then
    -- Villagers may not grief in protected areas.
    func.is_protected_owner = function(_, pos) -- (owner, pos)
        return minetest.is_protected(pos, "")
    end

else if owner_griefing_lc == "true" then
    -- Villagers may grief in areas protected by the owner.
    func.is_protected_owner = function(owner, pos)
        local myowner = owner or ""
        if myowner == "working_villages:self_employed" then
            myowner = ""
        end
        return minetest.is_protected(pos, myowner)
    end

else if owner_griefing_lc == "ignore" then
    -- Villagers ignore protected areas.
    func.is_protected_owner = function() return false end

else
    -- Villagers may grief in areas where "[owner_protection]:[owner_name]" is allowed.
    -- This makes sense with protection mods that grant permission to
    -- arbitrary "player names."
    func.is_protected_owner = function(owner, pos)
        local myowner = owner or ""
        if myowner == "" then
            myowner = ""
        else
            myowner = owner_griefing..":"..myowner
        end
        return minetest.is_protected(pos, myowner)
    end

    -- Patch areas to support this extension
    local prefixlen = #owner_griefing
    local areas = rawget(_G, "areas")
    if areas then
        local areas_player_exists = areas.player_exists
        function areas.player_exists(area, name)
            local myname = name
            if string.sub(name,prefixlen+1,prefixlen+1) == ":"
                    and string.sub(name,prefixlen+2)
                    and string.sub(name,1,prefixlen) == owner_griefing then
                myname = string.sub(name,prefixlen+2)
                if myname == "working_villages:self_employed" then
                    return true
                end
            end
            return areas_player_exists(area, myname)
        end
    end
end end end -- else else else

function func.is_protected(self, pos)
    return func.is_protected_owner(self.owner_name, pos)
end

-- chest manipulation support functions
func.chest_names = {
	["default:chest"]             = true,
	["default:chest_open"]        = true,
	["default:chest_locked"]      = true,
	["default:chest_locked_open"] = true,
}
if minetest.get_modpath("homedecor_office") then
	func.chest_names["homedecor_office:desk"]           = true
	func.chest_names["homedecor_office:filing_cabinet"] = true
end
if minetest.get_modpath("homedecor_kitchen") then
  -- TODO homedecor_kitchen:kitchen_cabinet_colorable..material
  -- TODO homedecor_kitchen:kitchen_cabinet_colored..material
  -- TODO homedecor_kitchen:kitchen_cabinet_colorable_with_drawers..material
  -- TODO homedecor_kitchen:kitchen_cabinet_colored_with_drawers..material
  -- TODO homedecor_kitchen:kitchen_cabinet_colorable_half..material
  -- TODO homedecor_kitchen:kitchen_cabinet_colored_half..material
  -- TODO homedecor_kitchen:kitchen_cabinet_colorable_with_sink..material
  -- TODO homedecor_kitchen:kitchen_cabinet_colored_with_sink..material
  -- TODO homedecor_kitchen:refrigerator_white
  -- TODO homedecor_kitchen:refrigerator_steel
end
if minetest.get_modpath("homedecor_bedroom") then
  -- TODO homedecor_bedroom:nightstand_..w.._one_drawer
  -- TODO homedecor_bedroom:nightstand_..w.._two_drawers
end
if minetest.get_modpath("homedecor_misc") then
	func.chest_names["homedecor_misc:cardboard_box"]     = true
	func.chest_names["homedecor_misc:cardboard_box_big"] = true
end
if minetest.get_modpath("homedecor_bathroom") then
	func.chest_names["homedecor_bathroom:medicine_cabinet"] = true
end
function func.is_chest(pos)
	local node = minetest.get_node(pos)
  if (node==nil) then
    return false;
  end
  if func.chest_names[node.name] then
    return true;
  end
  local is_chest = minetest.get_item_group(node.name, "chest");
  if (is_chest~=0) then
    return true;
  end
  return false;
end

func.furnace_names = {
	["default:furnace"]        = true,
	["default:furnace_active"] = true,
}
if minetest.get_modpath("homedecor_kitchen") then
	func.furnace_names["homedecor_kitchen:oven"]              = true
	func.furnace_names["homedecor_kitchen:oven_active"]       = true
	func.furnace_names["homedecor_kitchen:oven_steel"]        = true
	func.furnace_names["homedecor_kitchen:oven_steel_active"] = true
	func.furnace_names["homedecor:microwave_oven"]            = true
	func.furnace_names["homedecor:microwave_oven_active"]     = true
end
function func.is_furnace(pos)
	local node = minetest.get_node(pos)
  if (node==nil) then
    return false;
  end
  if func.furnace_names[node.name] then
    return true;
  end
  local is_furnace = minetest.get_item_group(node.name, "furnace"); -- oven ? idk
  return (is_furnace~=0)
end

function func.is_refinery(pos)
	local node = minetest.get_node(pos)
  if (node==nil) then
    return false;
  end
  if node.name=="biofuel:refinery"
  or node.name=="biofuel:refinery_active" then
    return true;
  end
  local is_refinery = minetest.get_item_group(node.name, "refinery"); -- oven ? idk
  return (is_refinery~=0)
end

function func.is_lockworkshop(pos)
	local node = minetest.get_node(pos)
  if (node==nil) then
    return false;
  end
  if node.name=="mcg_lockworkshop:lock_workshop" then
    return true;
  end
  local is_lockworkshop = minetest.get_item_group(node.name, "lockworkshop");
  return (is_lockworkshop~=0)
end

function func.is_fakerytable(pos)
	local node = minetest.get_node(pos)
  if (node==nil) then
    return false;
  end
  if node.name=="fakery:table" then
    return true;
  end
  --local is_fakerytable = minetest.get_item_group(node.name, "table");
  --if (is_fakerytable~=0) then
  --  return true;
  --end
  --return false;
  return false
end

function func.is_claycrafter(pos)
	local node = minetest.get_node(pos)
  if (node==nil) then
    return false;
  end
  if node.name=="claycrafter:claycrafter"
  or node.name=="claycrafter:claycrafter_active" then
    return true;
  end
  --local is_fakerytable = minetest.get_item_group(node.name, "claycrafter");
  --if (is_fakerytable~=0) then
  --  return true;
  --end
  --return false;
  return false
end

function func.is_recycler(pos)
	local node = minetest.get_node(pos)
  if (node==nil) then
    return false;
  end
  if node.name=="decraft:table"
  or node.name=="uncraft:uncrafttable" then
    return true;
  end
  --local is_fakerytable = minetest.get_item_group(node.name, "recycler");
  --if (is_fakerytable~=0) then
  --  return true;
  --end
  --return false;
  return false
end

function func.is_craft_table(pos)
	local node = minetest.get_node(pos)
  if (node==nil) then
    return false;
  end
  if node.name=="crafting_bench:workbench"
  or node.name=="craft_table:simple" then
    return true;
  end
  local is_chest = minetest.get_item_group(node.name, "craft_table");
  if (is_chest~=0) then
    return true;
  end
  return false;
end

-- modulo like in other languages
function func.mod(x, m)
  assert(x ~= nil)
  assert(m ~= nil)
  local r = x % m
  --if r < 0 then
  --	r = r+m
  --end
  r = r % m
  assert(0 <= r)
  assert(r <  m)
  return r
end

function func.is_dyemixer(pos)
  local node = minetest.get_node(pos)
  if (node==nil) then
    return false;
  end
  if node.name=="mcg_dyemixer:dye_mixer" then
    return true;
  end
  local is_chest = minetest.get_item_group(node.name, "dyemixer");
  if (is_chest~=0) then
    return true;
  end
  return false;
end

function func.take_everything(villager,stack)
  -- take everything from chest if room in inventory
  assert(villager ~= nil)
  assert(stack    ~= nil)
  local item_name = stack:get_name()
  local inv = villager:get_inventory()
  return (inv:room_for_item("main", stack))
end

function func.put_everything(villager,stack)
  -- put everything into chest
  assert(villager ~= nil)
  assert(stack    ~= nil)
  return true
end

function func.is_half_empty(villager)
  -- some jobs don't work so well unless the villager has room in his inventory
  assert(villager ~= nil)
  local inv = villager:get_inventory()
  local sz  = inv:get_size("main")
  local cnt = 0
  for i=1,sz,1 do
    local stk = inv:get_stack("main", i)
    if stk:is_empty() then cnt = cnt + 1 end
  end
  return cnt >= sz / 2
end

function func.is_beehive(pos)
  local node = minetest.get_node(pos)
  if (node==nil) then
    return false;
  end
  if node.name=="church_candles:hive"
  or node.name=="church_candles:hive_empty" then
    return true;
  end
  --local is_fakerytable = minetest.get_item_group(node.name, "beehive");
  --if (is_fakerytable~=0) then
  --  return true;
  --end
  --return false;
  return false
end

function func.is_fermenting_barrel(pos)
	local node = minetest.get_node(pos)
  if (node==nil) then
    return false;
  end
  if node.name=="wine:wine_barrel" then
    return true;
  end
  --local is_chest = minetest.get_item_group(node.name, "barrel");
  --if (is_chest~=0) then
  --  return true;
  --end
  return false;
end

return func
