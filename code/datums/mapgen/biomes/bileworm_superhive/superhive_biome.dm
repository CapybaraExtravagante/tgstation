/datum/map_generator/biome_applier/bileworm_superhive
	name = "Bileworm Superhive"
	selected_biome = /datum/biome/bileworm_superhive

/datum/biome/bileworm_superhive
	turf_type = /turf/open/misc/grass/jungle
	flora_types = list(/obj/structure/flora/grass/jungle/a/style_random,/obj/structure/flora/grass/jungle/b/style_random, /obj/structure/flora/tree/jungle/style_random, /obj/structure/flora/rock/pile/jungle/style_random, /obj/structure/flora/bush/jungle/a/style_random, /obj/structure/flora/bush/jungle/b/style_random, /obj/structure/flora/bush/jungle/c/style_random, /obj/structure/flora/bush/large/style_random, /obj/structure/flora/rock/pile/jungle/large/style_random)
	flora_density = 15

/datum/map_generator/cave_generator/lavaland/meaty
	name = "Bileworm Superhive"
	open_turf_types = list(/turf/open/floor/plating/asteroid/basalt/lava_land_surface = 1)
	closed_turf_types =  list(/turf/closed/wall/material/meat = 1)
