-- adapted from `feed_buckets`

-- fake player
function working_villages.villager:get_pos()
  return self.object:get_pos()
end
function working_villages.villager:set_pos(vel)
  return self.object:set_pos(vel)
end
function working_villages.villager:get_velocity()
  return self.object:get_velocity()
end
function working_villages.villager:add_velocity(vel)
  return self.object:add_velocity(vel)
end

function working_villages.villager:move_to(...)
  return self.object:move_to(...)
end
function working_villages.villager:punch(...)
  return self.object:punch(...)
end
function working_villages.villager:right_click(clicker)
  return self.object:right_click(clicker)
end

function working_villages.villager:get_wield_list()
  return self.object:get_wield_list()
end

function working_villages.villager:get_armor_groups()
  return self.object:get_armor_groups()
end
function working_villages.villager:set_armor_groups(groups)
  return self.object:set_armor_groups(groups)
end

function working_villages.villager:get_animation()
  return self.object:get_animation()
end

function working_villages.villager:set_animation_frame_speed(frame_speed)
  return self.object:set_animation_frame_speed(frame_speed)
end
function working_villages.villager:get_attach()
  return self.object:get_attach()
end
function working_villages.villager:set_attach(...)
  return self.object:set_attach(...)
end
function working_villages.villager:get_children()
  return self.object:get_children()
end
function working_villages.villager:set_detach()
  return self.object:set_detach()
end

function working_villages.villager:get_bone_position()
  return self.object:get_bone_position()
end
function working_villages.villager:set_bone_position(...)
  return self.object:set_bone_position(...)
end

function working_villages.villager:set_properties(vel)
  return self.object:set_properties(vel)
end

function working_villages.villager:get_nametag_attributes()
  return self.object:get_nametag_attributes()
end
function working_villages.villager:set_nametag_attributes(vel)
  return self.object:set_nametag_attributes(vel)
end

-- lua entity
function working_villages.villager:remove()
  return self.object:remove()
end

function working_villages.villager:set_velocity(vel)
  return self.object:set_velocity(vel)
end

function working_villages.villager:get_acceleration()
  return self.object:get_acceleration()
end
function working_villages.villager:set_acceleration(acc)
  return self.object:set_acceleration(acc)
end

function working_villages.villager:get_rotation()
  return self.object:get_rotation()
end
function working_villages.villager:set_rotation(rot)
  return self.object:set_rotation(rot)
end

function working_villages.villager:get_yaw()
  return self.object:get_yaw()
end
function working_villages.villager:set_yaw(yaw)
  return self.object:set_yaw(yaw)
end

function working_villages.villager:get_texture_mod()
  return self.object:get_texture_mod()
end
function working_villages.villager:set_texture_mod(mod)
  return self.object:set_texture_mod(mod)
end

function working_villages.villager:set_sprite(...)
  return self.object:set_sprite(...)
end

function working_villages.villager:get_luaentity()
  return self.object:get_luaentity()
end

-- player specific

function working_villages.villager:get_look_dir()
  return self.object:get_look_dir()
end
function working_villages.villager:get_look_vertical()
  return self.object:get_look_vertical()
end
function working_villages.villager:set_look_vertical(radians)
  return self.object:set_look_vertical(radians)
end
function working_villages.villager:get_look_horizontal()
  return self.object:get_look_horizontal()
end
function working_villages.villager:set_look_horizontal(radians)
  return self.object:set_look_horizontal(radians)
end

function working_villages.villager:get_breath()
  return self.object:get_breath()
end
function working_villages.villager:set_breath(value)
  return self.object:set_breath(value)
end

function working_villages.villager:get_fov()
  return self.object:get_fov()
end
function working_villages.villager:set_fov(fov, is_multiplier, transition_time)
  return self.object:set_fov(fov, is_multiplier, transition_time)
end

function working_villages.villager:get_meta()
  return self.object:get_meta()
end

function working_villages.villager:get_inventory_formspec()
  return self.object:get_inventory_formspec()
end
function working_villages.villager:set_inventory_formspec(formspec)
  return self.object:set_inventory_formspec(formspec)
end

function working_villages.villager:get_formspec_prepend(formspec)
  return self.object:get_formspec_prepend(formspec)
end
function working_villages.villager:set_formspec_prepend(formspec)
  return self.object:set_formspec_prepend(formspec)
end

function working_villages.villager:get_player_control()
  return self.object:get_player_control()
end
function working_villages.villager:get_player_control_bits()
  return self.object:get_player_control_bits()
end

function working_villages.villager:get_physic_override()
  return self.object:get_physic_override()
end
function working_villages.villager:set_physic_override(override_table)
  return self.object:set_physic_override(override_table)
end

function working_villages.villager:hud_add(hud_definition)
  return self.object:hud_add(hud_definition)
end
function working_villages.villager:hud_remove(id)
  return self.object:hud_remove(id)
end
function working_villages.villager:hud_change(id, stat, value)
  return self.object:hud_change(id, stat, value)
end
function working_villages.villager:hud_get(id)
  return self.object:hud_get(id)
end

function working_villages.villager:hud_get_flags()
  return self.object:hud_get_flags()
end
function working_villages.villager:hud_set_flags(flags)
  return self.object:hud_set_flags(flags)
end

function working_villages.villager:hud_get_hotbar_itemcount()
  return self.object:hud_get_hotbar_itemcount()
end
function working_villages.villager:hud_set_hotbar_itemcount(count)
  return self.object:hud_set_hotbar_itemcount(count)
end

function working_villages.villager:hud_get_hotbar_image()
  return self.object:hud_get_hotbar_image()
end
function working_villages.villager:hud_set_hotbar_image(texturename)
  return self.object:hud_set_hotbar_image(texturename)
end

function working_villages.villager:hud_get_hotbar_selected_image()
  return self.object:hud_get_hotbar_selected_image()
end
function working_villages.villager:hud_set_hotbar_selected_image(texturename)
  return self.object:hud_set_hotbar_selected_image(texturename)
end

function working_villages.villager:set_minimap_modes(modes, selected_mode)
  return self.object:set_minimap_mdoes(mdoes, selected_mode)
end

function working_villages.villager:get_sky()
  return self.object:get_sky()
end
function working_villages.villager:set_sky(sky_parameters)
  return self.object:set_sky(sky_parameters)
end
function working_villages.villager:get_sky_color()
  return self.object:get_sky_color()
end

function working_villages.villager:get_sun()
  return self.object:get_sun()
end
function working_villages.villager:set_sun(sun_parameters)
  return self.object:set_sun(sun_parameters)
end

function working_villages.villager:get_moon()
  return self.object:get_moon()
end
function working_villages.villager:set_moon(moon_parameters)
  return self.object:set_moon(moon_parameters)
end

function working_villages.villager:get_stars()
  return self.object:get_stars()
end
function working_villages.villager:set_stars(stars_parameters)
  return self.object:set_stars(stars_parameters)
end

function working_villages.villager:get_clouds()
  return self.object:get_clouds()
end
function working_villages.villager:set_clouds(clouds_parameters)
  return self.object:set_clouds(clouds_parameters)
end

function working_villages.villager:get_day_night_ratio()
  return self.object:get_day_night_ratio()
end
function working_villages.villager:override_day_night_ratio(ratio)
  return self.object:override_day_night_ratio(ratio)
end

function working_villages.villager:get_local_animation()
  return self.object:get_local_animation()
end
function working_villages.villager:set_local_animation(...)
  return self.object:set_local_animation(...)
end

function working_villages.villager:get_eye_offset()
  return self.object:get_eye_offset()
end
function working_villages.villager:set_eye_offset(...)
  return self.object:set_eye_offset(...)
end

function working_villages.villager:send_mapblock(blockpos)
  return self.object:send_mapblock(blockpos)
end

