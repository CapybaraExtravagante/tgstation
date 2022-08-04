/datum/map_generator/biome_applier/bileworm_superhive
	name = "Bileworm Superhive"
	selected_biome = /datum/biome/bileworm_superhive

/datum/biome/bileworm_superhive
	turf_type = /turf/open/misc/grass/jungle
	flora_types = list(
		/obj/structure/flora/rock/pile/jungle/style_random = 1,
	)
	flora_density = 15
	fauna_types = list(
		/mob/living/basic/bileworm,
	)
	fauna_density = 5

/datum/map_generator/cave_generator/lavaland/bileworm_superhive
	name = "Bileworm Superhive"
	open_turf_types = list(/turf/open/floor/mineral/wax/lavaland_atmos = 1)
	closed_turf_types =  list(/turf/closed/wall/material/wax = 1)
