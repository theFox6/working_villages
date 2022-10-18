local pathfinder = {}

local debug_pathfinder = true

--[[
minetest.get_content_id(name)
minetest.registered_nodes
minetest.get_name_from_content_id(id)
local ivm = a:index(pos.x, pos.y, pos.z)
local ivm = a:indexp(pos)
minetest.hash_node_position({x=,y=,z=})
minetest.get_position_from_hash(hash)

start_index, target_index, current_index
^ Hash of position

current_value
^ {int:hCost, int:gCost, int:fCost, hash:parent, vect:pos}
]]--


--print("loading pathfinder")

--TODO: route via climbable

local openSet = {}
local closedSet = {}

local function get_distance(start_pos, end_pos)
	local distX = math.abs(start_pos.x - end_pos.x)
	local distZ = math.abs(start_pos.z - end_pos.z)

	if distX > distZ then
		return 14 * distZ + 10 * (distX - distZ)
	else
		return 14 * distX + 10 * (distZ - distX)
	end
end

local function get_distance_to_neighbor(start_pos, end_pos)
	local distX = math.abs(start_pos.x - end_pos.x)
	local distY = math.abs(start_pos.y - end_pos.y)
	local distZ = math.abs(start_pos.z - end_pos.z)

	if distX > distZ then
		return (14 * distZ + 10 * (distX - distZ)) * (distY + 1)
	else
		return (14 * distX + 10 * (distZ - distX)) * (distY + 1)
	end
end

local function walkable(node)
		if string.find(node.name,"doors:") then
			return false
		else
			if minetest.registered_nodes[node.name]~= nil then
				return minetest.registered_nodes[node.name].walkable
			else
				return true
			end
		end
end

-- Check if we have @height clear nodes above cpos.
-- We already checked that cpos is clear.
local function check_clearance(cpos, height)
	for i = 1, height do
		local hpos = {x=cpos.x, y=cpos.y+i, z=cpos.z}
		local node = minetest.get_node(hpos)
		if walkable(node) then
			return false
		end
	end
	return true
end

assert(check_clearance)

local function get_neighbor_ground_level(pos, jump_height, fall_height)
	local node = minetest.get_node(pos)
	local height = 0
	if walkable(node) then
		repeat
			height = height + 1
			if height > jump_height then
				return nil
			end
			pos.y = pos.y + 1
			node = minetest.get_node(pos)
		until not(walkable(node))
		return pos
	else
		repeat
			height = height + 1
			if height > fall_height then
				return nil
			end
			pos.y = pos.y - 1
			node = minetest.get_node(pos)
		until walkable(node)
		return {x = pos.x, y = pos.y + 1, z = pos.z}
	end
end

local function get_neighbors(current_pos, entity_height, entity_jump_height, entity_fear_height)
	-- check to see if we can jump in the current pos
	local can_jump = check_clearance(current_pos, entity_height + entity_jump_height)
	local neighbors = {}
	local neighbors_index = 1
	for z = -1, 1 do
	for x = -1, 1 do
		local neighbor_pos = {x = current_pos.x + x, y = current_pos.y, z = current_pos.z + z}
		local neighbor = minetest.get_node(neighbor_pos)
		local neighbor_ground_level = get_neighbor_ground_level(neighbor_pos, entity_jump_height, entity_fear_height)
		local neighbor_clearance = false
		-- did we find a walkable node within range with a non-walkable node above?
		if neighbor_ground_level and can_jump or current_pos.y >= neighbor_ground_level.y then
			-- check headroom, if we are jumping, we need extra
			local needed_height = entity_height
			if neighbor_ground_level.y > current_pos.y then
				needed_height = needed_height + entity_jump_height - (neighbor_ground_level.y - current_pos.y)
			end
			neighbor_clearance = check_clearance(neighbor_pos, needed_height)
		end
		if neighbor_clearance and neighbor_ground_level then
			neighbors[neighbors_index] = {
				hash = minetest.hash_node_position(neighbor_ground_level),
				pos = neighbor_ground_level,
				clear = true,
				walkable = true, -- FIXME: clear and walkable are always the same
			}
		else
			neighbors[neighbors_index] = {
				hash = nil,
				pos = nil,
				clear = nil,
				walkable = nil,
			}
		end
		neighbors_index = neighbors_index + 1
	end -- for x
	end -- for z
	return neighbors
end

--TODO: path to the nearest of multiple endpoints
-- or first path nearest to the endpoint

-- illustrate the path -- adapted from minetest's pathfinder test.
local function show_particles(path)
	local prev = path[1]
	for s=1, #path do
		local pos = path[s]
		local t
		if s == #path then
			t = "testpathfinder_waypoint_end.png"
		elseif s == 1 then
			t = "testpathfinder_waypoint_start.png"
		else
			local tn = "testpathfinder_waypoint.png"
			if pos.y ~= prev.y then
				if pos.x == prev.x and pos.z == prev.z then
					if pos.y > prev.y then
						tn = "testpathfinder_waypoint_up.png"
					else
						tn = "testpathfinder_waypoint_down.png"
					end
				else
					tn = "testpathfinder_waypoint_jump.png"
				end
			end
			local c = math.floor(((#path-s)/#path)*255)
			t = string.format("%s^[multiply:#%02x%02x00", tn, 0xFF-c, c)
		end
		minetest.add_particle({
			pos = pos,
			expirationtime = 5 + 0.2 * s,
			playername = "singleplayer",
			glow = minetest.LIGHT_MAX,
			texture = t,
			size = 3,
		})
		prev = pos
	end
end


function pathfinder.find_path(pos, endpos, entity)
	--print("searching for a path to:" .. minetest.pos_to_string(endpos))
	local start_index = minetest.hash_node_position(pos)
	local target_index = minetest.hash_node_position(endpos)
	local count = 1

	openSet = {}
	closedSet = {}

	local h_start = get_distance(pos, endpos)
	openSet[start_index] = {hCost = h_start, gCost = 0, fCost = h_start, parent = nil, pos = pos}

	-- Entity values
	local entity_height = 2
	local entity_fear_height = 2
	local entity_jump_height = 1
	if entity then
		local collisionbox = entity.collisionbox or entity.initial_properties.collisionbox
		entity_height = math.ceil(collisionbox[5] - collisionbox[2])
		entity_fear_height = entity.fear_height or 2
		entity_jump_height = entity.jump_height or 1
	end

	repeat
		local current_index
		local current_values

		-- Get one index as reference from openSet
		current_index, current_values = next(openSet)

		-- Search for lowest fCost
		for i, v in pairs(openSet) do
			if v.fCost < openSet[current_index].fCost or v.fCost == current_values.fCost and v.hCost < current_values.hCost then
				current_index = i
				current_values = v
			end
		end

		openSet[current_index] = nil
		closedSet[current_index] = current_values
		count = count - 1

		if current_index == target_index then
			--print("Found path")
			local path = {}
			local reverse_path = {}
			repeat
				if not(closedSet[current_index]) then
					return {endpos} --was empty return
				end
				table.insert(path, closedSet[current_index].pos)
				current_index = closedSet[current_index].parent
				if #path > 100 then
					--print("path to long")
					return
				end
			until start_index == current_index
			for _,wp in pairs(path) do
				table.insert(reverse_path, 1, wp)
			end
			if #path ~= #reverse_path then
			 print("path's length is "..#path.." but reverse path has length "..#reverse_path)
			end
			--print("path length: "..#reverse_path)
			if debug_pathfinder then
				show_particles(path)
			end
			return reverse_path,path
		end

		local current_pos = current_values.pos

		local neighbors = get_neighbors(current_pos, entity_height, entity_jump_height, entity_fear_height)

		for id, neighbor in pairs(neighbors) do
			-- don't cut corners
			local cut_corner = false
			if id == 1 then
				if not(neighbors[id + 1].clear) or not(neighbors[id + 3].clear)
					or neighbors[id + 1].walkable or neighbors[id + 3].walkable then
					cut_corner = true
				end
			elseif id == 3 then
				if not neighbors[id - 1].clear or not neighbors[id + 3].clear
					or neighbors[id - 1].walkable or neighbors[id + 3].walkable then
					cut_corner = true
				end
			elseif id == 7 then
				if not neighbors[id + 1].clear or not neighbors[id - 3].clear
				or neighbors[id + 1].walkable or neighbors[id - 3].walkable then
					cut_corner = true
				end
			elseif id == 9 then
				if not neighbors[id - 1].clear or not neighbors[id - 3].clear
				or neighbors[id - 1].walkable or neighbors[id - 3].walkable then
					cut_corner = true
				end
			end

			if neighbor.hash ~= current_index and not closedSet[neighbor.hash] and neighbor.clear and not cut_corner then
				local move_cost_to_neighbor = current_values.gCost + get_distance_to_neighbor(current_values.pos, neighbor.pos)
				local gCost = 0
				if openSet[neighbor.hash] then
					gCost = openSet[neighbor.hash].gCost
				end
				if move_cost_to_neighbor < gCost or not openSet[neighbor.hash] then
					if not openSet[neighbor.hash] then
						count = count + 1
					end
					local hCost = get_distance(neighbor.pos, endpos)
					openSet[neighbor.hash] = {
							gCost = move_cost_to_neighbor,
							hCost = hCost,
							fCost = move_cost_to_neighbor + hCost,
							parent = current_index,
							pos = neighbor.pos
					}
				end
			end
		end
		if count > 100 then
			--print("failed finding a path to:" minetest.pos_to_string(endpos))
			return
		end
	until count < 1
	--print("count < 1")
	return {endpos}
end

pathfinder.walkable = walkable

function pathfinder.get_ground_level(pos)
	return get_neighbor_ground_level(pos, 30927, 30927)
end

return pathfinder
