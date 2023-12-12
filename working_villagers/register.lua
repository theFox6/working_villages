-- TODO more textures
working_villages.register_villager("working_villages:villager_male", {
	hp_max     = 30,
	weight     = 20,
	mesh       = "character.b3d",
	textures   = {"villager_male.png"},
	egg_image  = "villager_male_egg.png",
})
local product_name = "working_villages:villager_female"
local texture_name = "villager_female.png"
local egg_img_name = "villager_female_egg.png"
working_villages.register_villager(product_name, {
	hp_max     = 20,
	weight     = 18,
	mesh       = "character.b3d",
	textures   = {texture_name},
	egg_image  = egg_img_name,
})
