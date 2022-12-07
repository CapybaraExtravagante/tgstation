/datum/faction
	///Name of the faction
	var/name = "Example Faction"
	///Basic description of the faction, shown in comms console
	var/basic_desc = "An example of a faction, how neat!"
	///Primary color of the faction to use in UI background
	var/faction_color = "#5875ccff"
	///Current relationship value of the faction
	var/current_relationship = 0
	///SVG icon of this faction
	var/icon = "tg-nanotrasen-logo"

/datum/faction/proc/set_relationship(new_relationship_value)
	current_relationship = new_relationship_value

/datum/faction/proc/add_relationship(added_value)
	set_relationship(current_relationship + added_value)

/datum/faction/nanotrasen
	name = "NanoTrasen"
	basic_desc = "Our employers. Best to keep them happy!"
	faction_color = "#5875cc"
	current_relationship = 30 //Start at 30!
	icon = "tg-nanotrasen-logo"

/datum/faction/syndicate
	name = "The Syndicate"
	basic_desc = "Our competitors, and often our saboteurs."
	faction_color = "#a15050"
	icon = "tg-syndicate-logo"
