/datum/round_event_control/electrical_storm
	name = "Electrical Storm"
	typepath = /datum/round_event/electrical_storm
	earliest_start = 10 MINUTES
	min_players = 5
	weight = 20
	category = EVENT_CATEGORY_ENGINEERING
	description = "Destroys all lights in a large area."

/datum/round_event_control/electrical_storm/get_faction_weight_multiplier()
	var/datum/faction/ssc/ssc_faction = SSfactions.get_faction_instance(/datum/faction/ssc) /// The SSC keeps our local space safe, less safe is more events!
	switch(ssc_faction.relation_tier)
		if(FACTION_RELATION_LEVEL_HATED)
			return 3
		if(FACTION_RELATION_LEVEL_DISLIKED)
			return 2
		if(FACTION_RELATION_LEVEL_DISTRUSTED)
			return 1.5
		if(FACTION_RELATION_LEVEL_NEUTRAL) // Default level
			return 1
		if(FACTION_RELATION_LEVEL_APPRECIATED)
			return 0.9
		if(FACTION_RELATION_LEVEL_FRIENDLY)
			return 0.75
		if(FACTION_RELATION_LEVEL_BELOVED)
			return 0.5

/datum/round_event/electrical_storm
	var/lightsoutAmount = 1
	var/lightsoutRange = 25
	announce_when = 1

/datum/round_event/electrical_storm/announce(fake)
	priority_announce("An electrical storm has been detected in your area, please repair potential electronic overloads.", "Electrical Storm Alert")


/datum/round_event/electrical_storm/start()
	var/list/epicentreList = list()

	for(var/i in 1 to lightsoutAmount)
		var/turf/T = find_safe_turf()
		if(istype(T))
			epicentreList += T

	if(!epicentreList.len)
		return

	for(var/centre in epicentreList)
		for(var/a in GLOB.apcs_list)
			var/obj/machinery/power/apc/A = a
			if(get_dist(centre, A) <= lightsoutRange)
				A.overload_lighting()
