
/datum/map_generator/scalar_generator
	///A 2D list of the layer, to a /datum/generator_scalar_layer that returns a scalar for the layer. (0 to 1)
	var/list/generation_layers = list()

	///A list of thresholds for specific range of the layer to be selected. Goes from highest value to lowest. This list should be populated in the same order that we would go through the possible terrains.
	var/list/layer_thresholds = list()

	///A multi-dimensional list with all the levels of noise! Either nests lists, or a specific terrain.
	var/list/possible_terrains = list()

	///How much the x/y are offset randomly
	var/random_drift = DEFAULT_BIOME_RANDOM_SQUARE_DRIFT

/datum/map_generator/scalar_generator/New()
	. = ..()
	for(var/layer_name in generation_layers)
		var/datum/generator_scalar_layer/generator_layer_type = generation_layers[layer_name]
		var/datum/generator_scalar_layer/generator_layer_instance = new generator_layer_type()
		generation_layers[layer_name] = generator_layer_instance

///Seeds the rust-g perlin noise with a random number.
/datum/map_generator/scalar_generator/generate_terrain(list/turfs)
	. = ..()
	for(var/turf/gen_turf as anything in turfs)

		var/drift_x = (gen_turf.x + rand(-random_drift, random_drift))
		var/drift_y = (gen_turf.y + rand(-random_drift, random_drift))
		var/list/current_list_to_check = possible_terrains

		for(var/layer_name in layer_thresholds)
			var/datum/generator_scalar_layer/generator_layer_instance = generation_layers[layer_name]
			var/list/layer_specific_thresholds = layer_thresholds[layer_name]

			var/layer_scalar = generator_layer_instance.get_scalar(drift_x, drift_y)

			var/selected_threshold

			for(var/possible_range in layer_specific_thresholds)
				var/threshold = layer_specific_thresholds[possible_range]
				if(layer_scalar > threshold)
					selected_threshold = current_list_to_check[possible_range]
					break

			if(islist(selected_threshold)) //We just hit another list; which means we go to the next layer.
				current_list_to_check = selected_threshold
				continue

			if(ispath(selected_threshold, /datum/terrain))
				var/datum/terrain/selected_terrain = SSmapping.terrains[selected_threshold]
				selected_terrain.generate_turf(gen_turf)
				break
		CHECK_TICK
	return ..()

/turf/open/genturf
	name = "ungenerated turf"
	desc = "If you see this, and you're not a ghost, yell at coders"
	icon = 'icons/turf/debug.dmi'
	icon_state = "genturf"

/turf/open/genturf/alternative //currently used for edge cases in which you want a certain type of map generation intermingled with other genturfs
	name = "alternative ungenerated turf"
	desc = "If you see this, and you're not a ghost, yell at coders pretty loudly"
	icon_state = "genturf_alternative"
