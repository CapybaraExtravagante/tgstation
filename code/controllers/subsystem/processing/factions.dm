/// The subsystem used to tick [/datum/faction] instances. Takes care of the processing of factions and the requests they might have.
PROCESSING_SUBSYSTEM_DEF(factions)
	name = "Factions"
	flags = SS_POST_FIRE_TIMING|SS_BACKGROUND
	priority = FIRE_PRIORITY_FACTIONS
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	init_order = INIT_ORDER_FACTIONS
	wait = 10 SECONDS //Do not need to tick often! Players wont notice if things are a bit delayed for this system.
	///List of all factions, key is the typepath while assigned value is a newly created instance of the typepath. See setup_factions()
	var/list/factions
	///Our current primary faction. By default this is NanoTrasen. This is the faction that gets affected by most of the actions you take as a crew.
	var/datum/faction/primary_faction = /datum/faction/nanotrasen

/datum/controller/subsystem/processing/factions/Initialize()
	setup_factions()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/processing/factions/proc/setup_factions()
	factions = list()
	for(var/faction_type in subtypesof(/datum/faction))
		var/datum/faction/faction_instance = new faction_type
		factions[faction_type] = faction_instance

/datum/controller/subsystem/processing/factions/proc/get_factions()
	return factions

/datum/controller/subsystem/processing/factions/proc/get_faction_instance(datum/faction/faction_type)
	return factions[faction_type]


/datum/controller/subsystem/processing/factions/proc/get_primary_faction()
	return factions[primary_faction]
