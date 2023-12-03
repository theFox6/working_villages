-- TODO not working




local follower = working_villages.require("jobs/follow_player")
local pathfinder = working_villages.require("pathfinder")

local hider = {}

local search_radius = 30
local step_height   = 1.1
local max_drop      = 2
local max_velocity  = 3
local algorithm     = "A*_noprefetch"

local up_vec1 = vector.new(0, 1, 0)
local up_vec2 = vector.new(0, 2, 0)
local rad_vec = vector.new(search_radius, search_radius, search_radius)

function get_max_velocity(dir, velocity)
	assert(max_velocity ~= nil)
	assert(dir          ~= nil)
	assert(velocity     ~= nil)

	assert(dir.x ~= nil)
	local x
	if dir.x >= 0 then x = math.min(dir.x,  max_velocity)
	else           x = math.max(dir.x, -max_velocity)
	end

	--local y = math.min(dir.y, max_velocity)
	local y = velocity.y

	assert(dir.z ~= nil)
	local z
	if dir.z >= 0 then z = math.min(dir.z,  max_velocity)
	else           z = math.max(dir.z, -max_velocity)
	end
	return {x = x, y = y, z = z}
end

function hider.walk_in_direction(v,dir)
	assert(v ~= nil)
	assert(dir ~= nil)
  local position = v.object:get_pos()
  --swim upward
  if dir.y > 1 and minetest.get_item_group(minetest.get_node(position).name,"liquid") > 0 then
    v:jump()
  end

  local velocity = v.object:get_velocity()
  if velocity.x==0 and velocity.y==0 then
    v:set_animation(working_villages.animation_frames.WALK)
  end
  --speed should actually be limited
  -- jeez she's fast... combined with a sleep timer of 300... well, let's just say she did hid
  --v.object:set_velocity{x = dir.x, y = velocity.y, z = dir.z}
  v.object:set_velocity(get_max_velocity(dir, velocity))
  v:set_yaw_by_direction(dir)

  --if villager is stoped by obstacle, the villager must jump.
  v:handle_obstacles(true)
end

function get_keys(t)
	assert(t ~= nil)
  local keys={}
  for key,_ in pairs(t) do
    table.insert(keys, key)
  end
  return keys
end

function shuffle(tbl)
  assert(tbl ~= nil)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

function hider.get_all_nodenames()
  return get_keys(minetest.registered_nodes)
end













function hider.is_found(v,pos)
  assert(v   ~= nil)
  assert(pos ~= nil)
  local stepsize = 1
  local up
  local can_see, blocking_node

  local players, mindis = v:get_near_players(search_radius,pos)
  for _, player in ipairs(players) do
    local player_position = player.position

    --up = {x=pos.x, y=pos.y+1, z=pos.z}
    up = vector.add(pos, up_vec1)
    can_see, blocking_node = minetest.line_of_sight(player_position, up, stepsize)
    if can_see == true then return true end
    assert(can_see == false)

    --up = {x=pos.x, y=pos.y+2, z=pos.z}
    up = vector.add(pos, up_vec2)
    can_see, blocking_node = minetest.line_of_sight(player_position, up, stepsize)
    if can_see == true then return true end
    assert(can_see == false)
  end

  return false
end

local trace_can_traverse = false
function hider.can_traverse(v, pos)
  if trace_can_traverse then print('hider.can_traverse() 1') end
  assert(v   ~= nil)
  if trace_can_traverse then print('hider.can_traverse() 2') end
  assert(pos ~= nil)
  if trace_can_traverse then print('hider.can_traverse() 3') end
  local position = v.object:get_pos()
  if trace_can_traverse then print('hider.can_traverse() 4') end
  assert(position ~= nil)
  if trace_can_traverse then print('hider.can_traverse() 5') end

  assert(search_radius ~= nil)
  if trace_can_traverse then print('hider.can_traverse() 6') end
  assert(step_height   ~= nil)
  if trace_can_traverse then print('hider.can_traverse() 7') end
  assert(max_drop      ~= nil)
  if trace_can_traverse then print('hider.can_traverse() 8') end

  if trace_can_traverse then
  print('position: (x='..position.x..', y='..position.y..', z='..position.z..')')
  print('pos     : (x='..     pos.x..', y='..     pos.y..', z='..     pos.z..')')
  print('radius  : '..search_radius)
  print('height  : '..step_height)
  print('drop    : '..max_drop)
  end

  -- TODO why can't it find any path ?
  --local path     = minetest.find_path(position,pos,search_radius,step_height,max_drop, algorithm)
  local path = pathfinder.find_path(position,pos,self)
  if trace_can_traverse then print('hider.can_traverse() 9') end
  if  path == nil then return false, nil end
  if trace_can_traverse then print('hider.can_traverse() 10') end
  if #path == 0   then return false, nil end
  if trace_can_traverse then print('hider.can_traverse() 11') end
--print('path found')
  return true, path
end

function hider.is_player_near(v, pos)
  --print('hider.is_player_near() 1')
  assert(v   ~= nil)
  --print('hider.is_player_near() 2')
  assert(pos ~= nil)
  --print('hider.is_player_near() 3')
  local player,player_position = v:get_nearest_player(search_radius,pos)
  --print('hider.is_player_near() 4')
  if player          == nil then return false end
  --print('hider.is_player_near() 5')
  if player_position == nil then return false end
  --print('hider.is_player_near() 6')
  return true
end

function hider.can_fit(pos)
  --print('hider.can_fit() 1')
  assert(pos ~= nil)
  --print('hider.can_fit() 2')
  local up
  local air

  up  = vector.add(pos, up_vec1)
  --print('hider.can_fit() 3')
  air = minetest.get_node(up)
  --print('hider.can_fit() 4')
  assert(air.name=="air")
  --print('hider.can_fit() 5')

  up  = vector.add(pos, up_vec2)
  --print('hider.can_fit() 6')
  air = minetest.get_node(up)
  --print('hider.can_fit() 7')
  if air.name ~= "air" then return false end
  --print('hider.can_fit() 8')

  return true
end

function filter(pred, list)
  --print('filter() 1')
  assert(pred ~= nil)
  --print('filter() 2')
  assert(list ~= nil)
  --print('filter() 3')
  local result = {}
  --print('filter() 4')
  for _, pos in ipairs(list) do
    --print('filter() 5')
    local flag = pred(pos)
    if flag == true then
      --print('filter() 6')
      table.insert(result, pos)
      --print('filter() 7')
    else assert(flag == false)
    end
    --print('filter() 8')
  end
  --print('filter() 9')
  assert(#result <= #list)
  --print('filter() 10')
  return result
end
function vfilter(v, pred, list)
  --print('filter() 1')
  assert(pred ~= nil)
  --print('filter() 2')
  assert(list ~= nil)
  --print('filter() 3')
  local result = {}
  --print('filter() 4')
  for _, pos in ipairs(list) do
    --print('filter() 5')
    local flag = pred(v, pos)
    if flag == true then
      --print('filter() 6')
      table.insert(result, pos)
      --print('filter() 7')
    else assert(flag == false)
    end
    --print('filter() 8')
  end
  --print('filter() 9')
  assert(#result <= #list)
  --print('filter() 10')
  return result
end

--function partial(f, head)
--  --print('partial() 1')
--  assert(f    ~= nil)
--  --print('partial() 2')
--  assert(head ~= nil)
--  --print('partial() 3')
--  return function(...)
--    f(head, unpack(...))
--  end
--end

local trace_find_path = false
function find_path(v, list)
  if trace_find_path then print('hider.find_path() 1') end
  assert(v    ~= nil)
  if trace_find_path then print('hider.find_path() 2') end
  assert(list ~= nil)
  if trace_find_path then print('hider.find_path() 3') end
  for _, pos in ipairs(list) do
    if trace_find_path then print('hider.find_path() 4') end
    local is_trav, path = hider.can_traverse(v, pos)
    if trace_find_path then print('hider.find_path() 5') end
    assert(is_trav ~= nil)
    if trace_find_path then print('hider.find_path() 6') end
    if is_trav == true then
      if trace_find_path then print('hider.find_path() 7') end
      assert(path ~= nil)
      if trace_find_path then print('hider.find_path() 8') end
      assert(#path >= 1)
      if trace_find_path then print('hider.find_path() 9') end
      local path_info = {
        path = path,
        index= 1,
      }
      if trace_find_path then print('hider.find_path() 10') end
      assert(path_info.path  ~= nil)
      if trace_find_path then print('hider.find_path() 11') end
      assert(path_info.index ~= nil)
      if trace_find_path then print('hider.find_path() 12') end
--print('path_info: '..table.concat(path_info))
      return path_info
    end
    assert(is_trav == false)
    if trace_find_path then print('hider.find_path() 13') end
  end
  if trace_find_path then print('hider.find_path() 14') end
  return nil
end

local trace_new_hiding_path = false
function hider.new_hiding_path(v)
  if trace_new_hiding_path then print('hider.new_hiding_path() 1') end
  assert(v   ~= nil)
  if trace_new_hiding_path then print('hider.new_hiding_path() 2') end
  local my_pos         = v.object:get_pos()
  if trace_new_hiding_path then print('hider.new_hiding_path() 3') end
  assert(my_pos ~= nil)
  if trace_new_hiding_path then print('hider.new_hiding_path() 4') end
  local minp           = vector.subtract(my_pos, rad_vec)
  if trace_new_hiding_path then print('hider.new_hiding_path() 5') end
  assert(minp ~= nil)
  if trace_new_hiding_path then print('hider.new_hiding_path() 6') end
  local maxp           = vector.add     (my_pos, rad_vec)
  if trace_new_hiding_path then print('hider.new_hiding_path() 7') end
  assert(maxp ~= nil)
  if trace_new_hiding_path then print('hider.new_hiding_path() 8') end
  local nodenames      = hider.get_all_nodenames()
  if trace_new_hiding_path then print('hider.new_hiding_path() 9') end
  assert(nodenames ~= nil)
  if trace_new_hiding_path then print('hider.new_hiding_path() 9') end
  local walkable_nodes = minetest.find_nodes_in_area_under_air(minp, maxp, nodenames)
  if trace_new_hiding_path then print('hider.new_hiding_path() 10') end
  if walkable_nodes == nil
  or #walkable_nodes == 0 then return nil end

  assert(hider.can_fit ~= nil)
  local fittable_nodes = filter(hider.can_fit, walkable_nodes)
  assert(fittable_nodes ~= nil)
  if trace_new_hiding_path then print('hider.new_hiding_path() 11') end
  if #fittable_nodes == 0 then return nil end

  assert(hider.is_player_near ~= nil)
  --local is_player_near = partial(hider.is_player_near, v)
  ----print('hider.new_hiding_path() 12')
  --assert(is_player_near ~= nil)
  ----print('hider.new_hiding_path() 13')

  --local near_nodes     = filter(is_player_near, fittable_nodes)
  local near_nodes = vfilter(v, hider.is_player_near, fittable_nodes)
  if trace_new_hiding_path then print('hider.new_hiding_path() 14') end
  assert(near_nodes ~= nil)
  if trace_new_hiding_path then print('hider.new_hiding_path() 15') end
  if #near_nodes == 0 then return nil end

  assert(hider.is_found ~= nil)
  --local is_found       = partial(hider.is_found, v)
  ----print('hider.new_hiding_path() 16')
  --assert(is_found ~= nil)
  ----print('hider.new_hiding_path() 17')

  --local unseen_nodes   = filter(is_found, near_nodes)
  local unseen_nodes = vfilter(v, hider.is_found, near_nodes)
  if trace_new_hiding_path then print('hider.new_hiding_path() 18') end
  assert(unseen_nodes ~= nil)
  if trace_new_hiding_path then print('hider.new_hiding_path() 19') end
  if #unseen_nodes == 0 then return nil end

  shuffle(unseen_nodes)
  if trace_new_hiding_path then print('hider.new_hiding_path() 20') end
  return find_path(v, unseen_nodes)
end

local trace_increment_hiding_path = true
function hider.increment_hiding_path(v)
  if trace_increment_hiding_path then print('hider.increment_hiding_path() 1') end
  assert(v   ~= nil)
  if trace_increment_hiding_path then print('hider.increment_hiding_path() 2') end
  local path_info = v.job_data.path_info
  if trace_increment_hiding_path then print('hider.increment_hiding_path() 3') end
  assert(path_info ~= nil)
  if trace_increment_hiding_path then print('hider.increment_hiding_path() 4') end
  local path      = path_info.path
  if trace_increment_hiding_path then print('hider.increment_hiding_path() 5') end
  assert(path ~= nil)
  if trace_increment_hiding_path then print('hider.increment_hiding_path() 6') end
  assert(#path >= 1)
  if trace_increment_hiding_path then print('hider.increment_hiding_path() 7') end
  local index     = path_info.index
  if trace_increment_hiding_path then print('hider.increment_hiding_path() 8') end
  assert(index ~= nil)
  if trace_increment_hiding_path then print('hider.increment_hiding_path() 9') end
  if index == #path then
				 --"keep walking another step for good measure," they say
				coroutine.yield()
    if trace_increment_hiding_path then print('hider.increment_hiding_path() 10') end
    v.job_data.path_info = nil
    if trace_increment_hiding_path then print('hider.increment_hiding_path() 11') end
    return
  end
  if trace_increment_hiding_path then print('hider.increment_hiding_path() 12') end
  path_info.index = index + 1
  if trace_increment_hiding_path then print('hider.increment_hiding_path() 13') end
  assert(v.job_data.path_info.index == path_info.index)
  if trace_increment_hiding_path then print('hider.increment_hiding_path() 14') end
  assert(v.job_data.path_info.index == index + 1)
  if trace_increment_hiding_path then print('hider.increment_hiding_path() 15') end
end

function hider.remember_path(v)
  --print('hider.remember_path() 1')
  assert(v   ~= nil)
  --print('hider.remember_path() 2')
  if v.job_data == nil then
    --print('hider.remember_path() 3')
    v.job_data = {}
    --print('hider.remember_path() 4')
  end
  --print('hider.remember_path() 5')
  local new_path = hider.new_hiding_path(v)
  --print('hider.remember_path() 6')
  v.job_data.path_info = new_path
  --print('hider.remember_path() 7')
  assert(v.job_data.path_info == nil or
         v.job_data.path_info.path  ~= nil)
  --print('hider.remember_path() 8')
  assert(v.job_data.path_info == nil or
         v.job_data.path_info.index ~= nil)
  --print('hider.remember_path() 9')
  return new_path
end

function hider.has_path(v)
  --print('hider.has_path() 1')
  assert(v   ~= nil)
  --print('hider.has_path() 2')
  if v.job_data == nil then return false end
  --print('hider.has_path() 3')

  local path_info = v.job_data.path_info
  --print('hider.has_path() 4')
  if path_info  == nil then return false end
  --print('hider.has_path() 5')
 
  --print('path_info: '..table.concat(path_info))

  local path  = path_info.path
if path == nil then
	print('unexpected nil path')
	return false
end -- wtf
  --print('hider.has_path() 6')
  assert(path  ~= nil)
  --print('hider.has_path() 7')
  assert(#path >= 1)
  --print('hider.has_path() 8')

  local index = path_info.index
  --print('hider.has_path() 9')
  assert(index ~= nil)
  --print('hider.has_path() 10')

  return true
end

function hider.get_destination(v)
  --print('hider.get_destination() 1')
  assert(v   ~= nil)
  --print('hider.get_destination() 2')
  local path_info = v.job_data.path_info
  --print('hider.get_destination() 3')
  assert(path_info ~= nil)
  --print('hider.get_destination() 4')
  local path      = path_info.path
  --print('hider.get_destination() 5')
  assert(path ~= nil)
  --print('hider.get_destination() 6')
  assert(#path >= 1)
  --print('hider.get_destination() 7')
  local destination = path[#path]
  --print('hider.get_destination() 8')
  assert(destination ~= nil)
  --print('hider.get_destination() 9')
  return destination
end

function hider.get_hiding_path(v)
  --print('hider.get_hiding_path() 1')
  assert(v   ~= nil)
  --print('hider.get_hiding_path() 2')
  if not hider.has_path(v) then
    --print('hider.get_hiding_path() 3')
    return hider.remember_path(v)
  end

  --print('hider.get_hiding_path() 4')
  local destination = hider.get_destination(v)
  --print('hider.get_hiding_path() 5')
  assert(destination ~= nil)
  --print('hider.get_hiding_path() 6')

  if     hider.is_found(v, destination) then 
    --print('hider.get_hiding_path() 7')
    return hider.remember_path(v)
  end

  --print('hider.get_hiding_path() 8')
  local is_trav, path = hider.can_traverse(v, destination)
  --print('hider.get_hiding_path() 9')
  if not is_trav then
    --print('hider.get_hiding_path() 10')
    return hider.remember_path(v)
  end
  --print('hider.get_hiding_path() 11')
  assert(path ~= nil)
  --print('hider.get_hiding_path() 12')
  assert(#path >= 1)
  --print('hider.get_hiding_path() 13')

  if not hider.is_player_near(v, destination) then
    --print('hider.get_hiding_path() 14')
    return hider.remember_path(v)
  end
  --print('hider.get_hiding_path() 15')

  return nil
end

function hider.get_hiding_spot(v)
  --print('hider.get_hiding_spot() 1')
  assert(v   ~= nil)
  --print('hider.get_hiding_spot() 2')
  local path_info = hider.get_hiding_path(v)
  --print('hider.get_hiding_spot() 3')
  if path_info == nil then return nil end
  --print('hider.get_hiding_spot() 4')

  local path     = path_info.path
  --print('hider.get_hiding_spot() 5')
  assert(path ~= nil)
  --print('hider.get_hiding_spot() 6')
  assert(#path >= 1)
  --print('hider.get_hiding_spot() 7')
  local index    = path_info.index
  --print('hider.get_hiding_spot() 8')
  assert(index ~= nil)
  --print('hider.get_hiding_spot() 9')
  local spot     = path[index]
  --print('hider.get_hiding_spot() 10')
  assert(spot ~= nil)
  --print('hider.get_hiding_spot() 11')
  --if v:is_near(spot, 1) then
  if v:is_near({x=spot.x,y=v.object:get_pos().y,z=spot.z}, 1) then
  --if v:is_near(spot, 0) then
  --if v:is_near(spot, 2) then
    --print('hider.get_hiding_spot() 12')
    hider.increment_hiding_path(v)
    --print('hider.get_hiding_spot() 13')
  end
  v:handle_obstacles(true)
  --print('hider.get_hiding_spot() 14')
  return spot
end

function hider.get_hiding_direction(v)
  --print('hider.get_hiding_direction() 1')
  assert(v   ~= nil)
  --print('hider.get_hiding_direction() 2')
  local position = v.object:get_pos()
  --print('hider.get_hiding_direction() 3')
  local player,player_position = v:get_nearest_player(search_radius,position)
  --print('hider.get_hiding_direction() 4')
  --local direction = vector.new(0,0,0)
  if player==nil then return nil end
  --print('hider.get_hiding_direction() 5')

  local destination = hider.get_hiding_spot(v)
  --print('hider.get_hiding_direction() 6')
  if destination == nil then return nil end
  --print('hider.get_hiding_direction() 7')
  return vector.subtract(destination, position)
end

function hider.step(v)
  --print('hider.step() 1')
  assert(v   ~= nil)
  --print('hider.step() 2')

  local position = v.object:get_pos()
  --print('hider.step() 3')

  if      hider.is_player_near(v, position)
  and not hider.is_found(v, position) then
    follower.stop(v)
    return
  end
  --print('hider.step() 4')

  local direction = hider.get_hiding_direction(v)
  --print('hider.step() 5')
  if direction == nil then
    follower.stop(v)
    return
  end
  --print('hider.step() 6')

  if vector.length(direction) < 3 then
    --print('hider.step() 7')
    --swim upward
    if direction.y > 1 and minetest.get_item_group(minetest.get_node(position).name,"liquid") > 0 then
      --print('hider.step() 8')
      v:jump()
      --print('hider.step() 9')
    end

    --follower.stop(v)
  else
    --follower.walk_in_direction(v,direction)
  end
  --print('hider.step() 10')
  if vector.length(direction) < 1 then
    --print('hider.step() 11 a')
    follower.stop(v)
    --print('hider.step() 12 a')
  else
    --print('hider.step() 11 b')
    hider.walk_in_direction(v,direction)
    --print('hider.step() 12 b')
  end
  --print('hider.step() 13')
end

local hider_tools = {
	-- need an anti torch
--	["default:torch"] = 99,
}
working_villages.register_job("working_villages:job_hider", {
  description      = "hider (working_villages)",
  long_description = "I'll just follow you wherever you go.",
  inventory_image  = "default_paper.png^memorandum_letters.png",
  jobfunc = function(v)
    local stack  = v:get_wield_item_stack()
    if stack:is_empty() then
        v:move_main_to_wield(function(name)
          return hider_tools[name] ~= nil
    	end)
    end
    while (v.pause) do
      coroutine.yield()
    end
--    v:count_timer("hider:change_dir")
--    if v:timer_exceeded("hider:change_dir",3) then
--	    v.job_data.target_position = nil
--    end
    hider.step(v)
  end,
})

return hider
