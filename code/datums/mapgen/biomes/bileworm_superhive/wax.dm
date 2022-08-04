/datum/material/wax
	name = "wax"
	desc = "Pliable material secreted by insects. Strong for something entirely natural."
	color = "#97865b"
	greyscale_colors = "#97865b"
	strength_modifier = 0.7
	//could add a sheet_type in the future just in case people wanna build bee hives
	categories = list()
	value_per_unit = 0.015
	beauty_modifier = -0.04
	armor_modifiers = list(MELEE = 1.5, BULLET = 1.1, LASER = 0.3, ENERGY = 0.5, BOMB = 1, BIO = 1, FIRE = 1.1, ACID = 1)

/turf/open/floor/mineral/wax
	name = "waxy floor"
	icon_state = "wax"
	material_flags = MATERIAL_GREYSCALE | MATERIAL_EFFECTS
	floor_tile = /obj/item/stack/tile/mineral/gold
	icons = list("wax","wax_dam")
	custom_materials = list(/datum/material/gold = 500)

/turf/open/floor/mineral/wax/lavaland_atmos
	initial_gas_mix = LAVALAND_DEFAULT_ATMOS
	planetary_atmos = TRUE
	baseturfs = /turf/open/floor/mineral/wax/lavaland_atmos

/turf/closed/wall/material/wax
	custom_materials = list(/datum/material/wax = 4000)
