local follower = {}
local S = minetest.get_translator("working_villages")

function follower.walk_in_direction(v,dir)
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
  v.object:set_velocity{x = dir.x, y = velocity.y, z = dir.z}
  v:set_yaw_by_direction(dir)

  --if villager is stoped by obstacle, the villager must jump.
  v:handle_obstacles(true)
end

function follower.stop(v)
  local velocity = v.object:get_velocity()
  if velocity.x~=0 or velocity.y~=0 then
    v:set_animation(working_villages.animation_frames.STAND)
    v.object:set_velocity{x = 0, y = velocity.y, z = 0}
  end
end

function follower.step(v)
  local position = v.object:get_pos()
  local player,player_position = v:get_nearest_player(10,position)
  local direction = vector.new(0,0,0)
  if player~=nil then
    direction = vector.subtract(player_position, position)
  end

  if vector.length(direction) < 3 then
    --swim upward
    if direction.y > 1 and minetest.get_item_group(minetest.get_node(position).name,"liquid") > 0 then
      v:jump()
    end

    follower.stop(v)
  else
    follower.walk_in_direction(v,direction)
  end
end

local follower_tools = {
	-- need a 3d armor light for the villagers
	["default:torch"] = 99,
}
-- TODO collect nearby items that the player has dropped, etc. (e.g., by digging)
working_villages.register_job("working_villages:job_folow_player", {
  description      = "follower (working_villages)",
  long_description = "I'll just follow you wherever you go.",
  inventory_image  = "default_paper.png^memorandum_letters.png",
  trivia = {
    "My job position is among the originals, upon which the rest are based.",
  },
  workflow = {
    "Equip my tool",
    "Follow the player",
  },
  jobfunc = function(v)
    local stack  = v:get_wield_item_stack()
    if stack:is_empty() then
        v:move_main_to_wield(function(name)
          return follower_tools[name] ~= nil
    	end)
    end
    while (v.pause) do
      coroutine.yield()
    end
    follower.step(v)
  end,
})

return follower
