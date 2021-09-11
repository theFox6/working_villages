working_villages.require("jobs/plant_collector")

local herb_names = {}
for name,_ in pairs(working_villages.herbs.names) do
    herb_names[#herb_names + 1] = name
end
for name,_ in pairs(working_villages.herbs.groups) do
    herb_names[#herb_names + 1] = "group:"..name
end

local function spawn(pos, node, active_object_count, active_object_count_wider)
    if active_object_count_wider > 2 then return end
        local pos1 = {x=pos.x-4,y=pos.y-8,z=pos.z-4}
        local pos2 = {x=pos.x+4,y=pos.y+1,z=pos.z+4}
    local spawn_pos
    for _,pos in ipairs(minetest.find_nodes_in_area_under_air(
            pos1,pos2,"group:soil")) do
        local above = minetest.get_node({x=pos.x,y=pos.y+2,z=pos.z})
        local above_def = minetest.registered_nodes[above.name] 
        if above_def and not above_def.groups.walkable then
            local gender = {
                "working_villages:villager_male",
                "working_villages:villager_female",
            }
            local self = minetest.add_entity(
                {x=pos.x,y=pos.y+1,z=pos.z},gender[math.random(2)], ""
            )
            return
        end
    end
end

minetest.register_abm({
    label = "Spawn herb collector",
    nodenames = herb_names,
    neighbors = "air",
    interval = 180,
    chance = 1000,
    catch_up = false,
    action = spawn,
})
