local log = working_villages.require("log")

local spawn_check = not working_villages.setting_enabled(
    "spawn_near_civilization",
    false)

local function spawner(initial_job)
    return function(pos, node, active_object_count, active_object_count_wider)
        if active_object_count_wider > 1 then return end

        if spawn_check then
            for _,p in ipairs(minetest.find_nodes_with_meta(
                    {x=pos.x-50,y=pos.y-50,z=pos.z-50},
                    {x=pos.x+50,y=pos.y+50,z=pos.z+50})) do
                if minetest.get_meta(p):contains("owner") then
                    log.action("Avoiding messing with someone's stuff.")
                    return
                end
            end
        end

        local pos1 = {x=pos.x-4,y=pos.y-8,z=pos.z-4}
        local pos2 = {x=pos.x+4,y=pos.y+1,z=pos.z+4}
        local spawn_pos
        for _,pos in ipairs(minetest.find_nodes_in_area_under_air(
                pos1,pos2,"group:soil")) do
            local above = minetest.get_node({x=pos.x,y=pos.y+2,z=pos.z})
            local above_def = minetest.registered_nodes[above.name] 
            if above_def and not above_def.groups.walkable then
                log.action("Spawning a %s at %s", initial_job, minetest.pos_to_string(pos,0))
                local gender = {
                    "working_villages:villager_male",
                    "working_villages:villager_female",
                }
                local new_villager = minetest.add_entity(
                    {x=pos.x,y=pos.y+1,z=pos.z},gender[math.random(2)], ""
                )
                local entity = new_villager:get_luaentity()
                entity.new_job = initial_job
                entity.owner_name = "working_villages:self_employed"
                entity:update_infotext()
                return
            end
        end
    end
end

working_villages.require("jobs/plant_collector")

local herb_names = {}
for name,_ in pairs(working_villages.herbs.names) do
    herb_names[#herb_names + 1] = name
end
for name,_ in pairs(working_villages.herbs.groups) do
    herb_names[#herb_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn herb collector",
    nodenames = herb_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_herbcollector"),
})

minetest.register_abm({
    label = "Spawn woodcutter",
    nodenames = "group:tree",
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_woodcutter"),
})

