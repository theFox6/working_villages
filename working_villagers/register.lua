local   male_textures = {"villager_male.png",}

local product_name = "working_villages:villager_female"
local texture_name = "villager_female.png"
local egg_img_name = "villager_female_egg.png"
local female_textures = {texture_name,}

-- TODO testing
--local male_textures   = {}
--local female_textures = {}



-- TODO check whether I sorted the male/female textures properly... I'm doing this by looking at the previews in the file manager
if minetest.get_modpath("airutils") then
	--table.insert(  male_textures, "pilot_clothes1.png")
	--table.insert(  male_textures, "pilot_clothes2.png")
	--table.insert(  male_textures, "pilot_clothes3.png")
	--table.insert(  male_textures, "pilot_clothes4.png")

	table.insert(female_textures, "pilot_novaskin_girl.png")
	table.insert(female_textures, "pilot_novaskin_girl_2.png")
	table.insert(female_textures, "pilot_novaskin_girl_steampunk.png")
	table.insert(female_textures, "pilot_novaskin_girl_steampunk_2.png")
end

if minetest.get_modpath("item_holders") then
	table.insert(  male_textures, "item_holders_mannequin.png")
	table.insert(female_textures, "item_holders_mannequin.png")
end

if minetest.get_modpath("mobf_trader") then
	table.insert(  male_textures, "baeuerin.png")
	table.insert(  male_textures, "bauer_in_sonntagskleidung.png")
	table.insert(  male_textures, "blacksmith.png")
	table.insert(  male_textures, "holzfaeller.png")
	table.insert(  male_textures, "kuhhaendler.png")
	table.insert(  male_textures, "tomatenhaendler.png")
	table.insert(  male_textures, "wheat_farmer_by_addi.png")
end

if minetest.get_modpath("mobs_npcs") then
	table.insert(  male_textures, "mobs_igor.png")
	table.insert(  male_textures, "mobs_igor2.png")
	table.insert(  male_textures, "mobs_igor3.png")
	table.insert(  male_textures, "mobs_igor4.png")
	table.insert(  male_textures, "mobs_igor5.png")
	table.insert(  male_textures, "mobs_igor6.png")
	table.insert(  male_textures, "mobs_igor7.png")
	table.insert(  male_textures, "mobs_igor8.png")
	table.insert(  male_textures, "mobs_npc.png")
	table.insert(female_textures, "mobs_npc2.png")
	table.insert(  male_textures, "mobs_npc3.png")
	table.insert(female_textures, "mobs_npc4.png")
	table.insert(  male_textures, "mobs_npc5.png")
	table.insert(female_textures, "mobs_npc6.png")
	--table.insert(  male_textures, "mobs_npc_baby.png")
	table.insert(  male_textures, "mobs_npc_shop_icon.png")
	table.insert(  male_textures, "mobs_trader.png")
	table.insert(  male_textures, "mobs_trader2.png")
	table.insert(  male_textures, "mobs_trader3.png")
	table.insert(  male_textures, "mobs_trader4.png")
end

if minetest.get_modpath("petz") then
	table.insert(  male_textures, "petz_mr_pumpkin.png")
	table.insert(  male_textures, "petz_santa_killer.png")
	table.insert(  male_textures, "petz_werewolf_black.png")
	table.insert(  male_textures, "petz_werewolf_brown.png")
	table.insert(  male_textures, "petz_werewolf_dark_gray.png")
	table.insert(  male_textures, "petz_werewolf_gray.png")

	table.insert(female_textures, "petz_werewolf_black.png")
	table.insert(female_textures, "petz_werewolf_brown.png")
	table.insert(female_textures, "petz_werewolf_dark_gray.png")
	table.insert(female_textures, "petz_werewolf_gray.png")
end

if minetest.get_modpath("skinsdb") then
	table.insert(  male_textures, "character_castaway_male.png")
	table.insert(  male_textures, "character_farmer_male.png")
	table.insert(  male_textures, "character_prince.png")
	table.insert(  male_textures, "character_rogue_male.png")

	table.insert(female_textures, "character_castaway_female.png")
	table.insert(female_textures, "character_farmer_female.png")
	table.insert(female_textures, "character_princess.png")
	table.insert(female_textures, "character_rogue_female.png")
end

-- space/spacesuit conflicts with spacesuit
--if minetest.get_modpath("spacesuit") then
--	table.insert(  male_textures, "spacesuit_sp2.png")
--	table.insert(female_textures, "spacesuit_sp2.png")
--end

assert(#male_textures ~= 0)
assert(#female_textures ~= 0)

working_villages.register_villager("working_villages:villager_male", {
	hp_max     = 30,
	weight     = 20,
	mesh       = "character.b3d",
	textures   = male_textures,
	egg_image  = "villager_male_egg.png",
})
working_villages.register_villager(product_name, {
	hp_max     = 20,
	weight     = 18,
	mesh       = "character.b3d",
	textures   = female_textures,
	egg_image  = egg_img_name,
})
-- TODO little villagers
