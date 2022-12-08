/datum/faction
	///Name of the faction
	var/name = "Example Faction"
	///Basic description of the faction, shown in comms console
	var/basic_desc = "An example of a faction, how neat!"
	///Primary color of the faction to use in UI background
	var/faction_color = "rgba(0, 0, 0, 0.7)"
	///Current relationship value of the faction
	var/current_relationship = 0
	///SVG icon of this faction
	var/icon = "tg-nanotrasen-logo"
	///Current relationship "tier"
	var/relation_tier = FACTION_RELATION_LEVEL_NEUTRAL
	///Messages that get sent out when reaching specific tiers in the faction relation. Only get sent out the first time on reaching this relation tier.______qdel_list_wrapper(list/L)
	var/relation_update_messages = list()


/datum/faction/New()
	. = ..()
	update_relationship_status(TRUE) //No need to make announcements the first time!

#define FACTION_RELATION_LEVEL_HATED_THRESHOLD -75
#define FACTION_RELATION_LEVEL_DISLIKED_THRESHOLD -50
#define FACTION_RELATION_LEVEL_DISTRUSTED_THRESHOLD -25
#define FACTION_RELATION_LEVEL_APPRECIATED_THRESHOLD 25
#define FACTION_RELATION_LEVEL_FRIENDLY_THRESHOLD 50
#define FACTION_RELATION_LEVEL_BELOVED_THRESHOLD 75

///Sets the current relationship level, sends a status update if required.
/datum/faction/proc/set_relationship(new_relationship_value)
	var/old_relationship = current_relationship
	current_relationship = new_relationship_value
	update_relationship_status()

///Adds to the relationship value by a specified amount
/datum/faction/proc/add_relationship(added_value)
	set_relationship(current_relationship + added_value)

///Handles sending updates when a relationship milestone is reached. Should be overriden by children.
/datum/faction/proc/update_relationship_status(silent = FALSE)

	var/new_tier

	switch(current_relationship)
		if(-INFINITY to FACTION_RELATION_LEVEL_HATED_THRESHOLD)
			new_tier = FACTION_RELATION_LEVEL_HATED
		if(FACTION_RELATION_LEVEL_HATED_THRESHOLD to FACTION_RELATION_LEVEL_DISLIKED_THRESHOLD)
			new_tier = FACTION_RELATION_LEVEL_DISLIKED
		if(FACTION_RELATION_LEVEL_DISLIKED_THRESHOLD to FACTION_RELATION_LEVEL_DISTRUSTED_THRESHOLD)
			new_tier = FACTION_RELATION_LEVEL_DISTRUSTED
		if(FACTION_RELATION_LEVEL_DISTRUSTED_THRESHOLD to FACTION_RELATION_LEVEL_APPRECIATED_THRESHOLD)
			new_tier = FACTION_RELATION_LEVEL_NEUTRAL
		if(FACTION_RELATION_LEVEL_APPRECIATED_THRESHOLD to FACTION_RELATION_LEVEL_FRIENDLY_THRESHOLD)
			new_tier = FACTION_RELATION_LEVEL_APPRECIATED
		if(FACTION_RELATION_LEVEL_FRIENDLY_THRESHOLD to FACTION_RELATION_LEVEL_BELOVED_THRESHOLD)
			new_tier = FACTION_RELATION_LEVEL_LIKED
		if(FACTION_RELATION_LEVEL_BELOVED_THRESHOLD to INFINITY)
			new_tier = FACTION_RELATION_LEVEL_BELOVED

	if(new_tier != relation_tier)
		relation_tier = new_tier

	if(!silent)
		if(relation_update_messages[relation_tier])
			var/datum/comm_message/relationship_update_message = new(name, relation_update_messages[relation_tier])

			relation_update_messages -= relation_tier

/datum/faction/proc/get_cargo_crate_price_mult()

/datum/faction/nanotrasen
	name = "NanoTrasen"
	basic_desc = "Our employers. Best to keep them happy!"
	faction_color = "rgba(9, 35, 55, 0.7)"
	current_relationship = 20 //Start at 20!
	icon = "phone" //"tg-nanotrasen-logo"

	relation_update_messages = list(
		FACTION_RELATION_LEVEL_HATED = "You will hear from us.",
		FACTION_RELATION_LEVEL_APPRECIATED

	)

/datum/faction/nanotrasen/get_cargo_crate_price_mult()
	switch(current_relationship)
		if(-100 to -50)
			return 2
		if(-50 to -10)
			return 1.5
		if(-10 to 25) // 25 is the default for NT
			return 1
		if(25 to 50)
			return 0.9
		if(50 to 100)
			return 0.8

/datum/faction/syndicate
	name = "The Syndicate"
	basic_desc = "Our competitors, and often our saboteurs."
	faction_color = "rgba(74, 0, 1, 0.7)"
	current_relationship = -100 //They don't like us
	icon = "phone" //"tg-syndicate-logo"

/datum/faction/syndicate/get_cargo_crate_price_mult()
	switch(current_relationship)
		if(-100 to -50)
			return 2
		if(-50 to -10)
			return 1.5
		if(-10 to 25) // 25 is the default for NT
			return 1
		if(25 to 50)
			return 0.9
		if(50 to 100)
			return 0.8

/datum/faction/ssc
	name = "Spinward Stellar Coalition"
	basic_desc = "The closest thing we have to a local government. Best to keep these people on our good side if we want to stay safe."
	faction_color = "rgba(218, 199, 120, 0.7)"
	current_relationship = 0 //They're neutral
	icon = "phone" //"tg-syndicate-logo"
