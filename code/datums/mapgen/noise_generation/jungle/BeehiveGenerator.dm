#define BEEHIVE_WALL "beehive_wall"
#define BEEHIVE_CORE "beehive_core"
#define OUTSIDE "outside"


/datum/map_generator/scalar_generator/beehive
	generation_layers = list(PERLIN_LAYER_HEIGHT = /datum/generator_scalar_layer/perlin_noise)

	layer_thresholds = list(
		PERLIN_LAYER_HEIGHT = list(
			OUTSIDE = 0.9,
			BEEHIVE_WALL = 0.8,
			BEEHIVE_CORE = 0
		),
	)

	possible_terrains = list(
		BEEHIVE_WALL = /datum/terrain/mountain,
		BEEHIVE_CORE = /datum/map_generator/cave_generator,
		OUTSIDE = /datum/terrain/wasteland
		)


/area/lavaland/surface/outdoors/unexplored/beehive
	map_generator = /datum/map_generator/scalar_generator/beehive
