-- add groups for some nodes to be managed by working_villagers

local list_of_doors = {
	"doors:door_wood_a"
}

local list_of_chests = {
	"default:chest"
}

for _,name in pairs(list_of_chests) do
	local item_def = minetest.registered_items[name]
	if (item_def~=nil) then
		local groups = table.copy(item_def.groups)
		groups.villager_chest = 1
		minetest.override_item(name, {groups=groups})
	end
end

local list_of_bed_top = {
	"beds:bed_top"
}
for _,name in pairs(list_of_bed_top) do
	local item_def = minetest.registered_items[name]
	if (item_def~=nil) then
		local groups = table.copy(item_def.groups)
		groups.villager_bed_top = 1
		minetest.override_item(name, {groups=groups})
	end
end

local list_of_bed_bottom = {
	"beds:bed_bottom"
}
for _,name in pairs(list_of_bed_bottom) do
	local item_def = minetest.registered_items[name]
	if (item_def~=nil) then
		local groups = table.copy(item_def.groups)
		groups.villager_bed_bottom = 1
		minetest.override_item(name, {groups=groups})
	end
end

