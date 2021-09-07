working_villages.require("jobs/plant_collector")

local herb_names = {}
for name,_ in pairs(working_villages.herbs.names) do
    herb_names[#herb_names + 1] = name
end
for name,_ in pairs(working_villages.herbs.groups) do
    herb_names[#herb_names + 1] = name
end

local function spawn(pos, node, active_object_count, active_object_count_wider)
    if active_object_count_wider > 2 then return end
        local pos1 = {x=pos.x-4,y=pos.y-8,z=pos.z-4}
        local pos2 = {x=pos.x+4,y=pos.y+1,z=pos.z+4}
    local spawn_pos
    for i,pos in ipairs(minetest.find_nodes_in_area_under_air(
            pos1,pos2,{"groups:walkable"})) do
        local above = minetest.get_node({x=pos.x,y=pos.y+2,z=pos.z})
        local above_def = minetest.registered_nodes[above.name] 
                if above_def and above_def.groups.walkable then
            spawn_pos = pos
            goto found
        end
    end
    return

    ::found::
    local gender = {"working_villages:villager_male","working_villages:villager_female"}[math.random(2)]
    local self = minetest.add_entity(spawn_pos,gender)
    local inv = self:get_inventory()
    local job = working_villages.job_inv:remove_item(
        "main","working_villages:job_herbcollector") 
    inv:set_stack("job", 1, job)
end

minetest.register_abm({
    label = "Spawn herb collector",
    nodenames = herb_names,
    neighbors = "air",
    interval = 180,
    chance = 1000,
    catch_up =false,
    action = spawn,
})
