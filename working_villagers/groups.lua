-- add groups for some nodes to be managed by working_villagers

local list_of_doors = {
	"doors:door_wood_a",
	"doors:door_wood_c",

	"doors:door_glass_a",
	"doors:door_glass_c",

	"doors:door_steel_a",
	"doors:door_steel_c",

	"doors:door_obsidian_glass_a",
	"doors:door_obsidian_glass_c",

	"doors:door_steel_bar_a",
	"doors:door_steel_bar_c",

	"doors:gate_wood",
	"doors:gate_pine_wood",
	"doors:gate_aspen_wood",
	"doors:gate_junglewood",
	"doors:gate_acacia_wood",
}

for _,name in pairs(list_of_doors) do
	local item_def = minetest.registered_items[name]
	if (item_def~=nil) then
		local groups = table.copy(item_def.groups)
		groups.villager_door = 1
		minetest.override_item(name, {groups=groups})
	end
end

local list_of_chests = {
	"default:chest",
	"default:chest_locked",
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
	"beds:bed_top",
	"beds:fancy_bed_top",
	"sleeping_mat:mat_top",
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
	"beds:bed_bottom",
	"beds:fancy_bed_bottom",
	"sleeping_mat:mat_bottom",
}
for _,name in pairs(list_of_bed_bottom) do
	local item_def = minetest.registered_items[name]
	if (item_def~=nil) then
		local groups = table.copy(item_def.groups)
		groups.villager_bed_bottom = 1
		minetest.override_item(name, {groups=groups})
	end
end

