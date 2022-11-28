///Changes the icon of a mob based on whether it's dead or alive. Can optionally also use gibbing animations or flip the sprite.
/datum/element/death_icon_handling
	element_flags = ELEMENT_BESPOKE
	argument_hash_start_idx = 2
	/// The icon state to change to if the character dies
	var/icon_dead
	/// Whether to flip the character on death. Defaults to current icon state of mob
	var/flip_on_death = FALSE
	///The icon to set if the character is alive. Defaults to current icon state of mob
	var/icon_alive

/datum/element/death_icon_handling/Attach(atom/target, icon_dead, flip_on_death = FALSE, icon_alive)
	. = ..()
	if(!isliving(target))
		return ELEMENT_INCOMPATIBLE

	if(icon_dead)
		src.icon_dead = icon_dead
	else
		icon_dead = living_mob.icon_state
	src.flip_on_death = flip_on_death
	if(icon_alive)
		src.icon_alive = icon_alive
	else
		icon_alive = living_mob.icon_state

	RegisterSignal(living_mob, COMSIG_LIVING_REVIVE, PROC_REF(on_revive))
	RegisterSignal(living_mob, COMSIG_LIVING_DEATH, PROC_REF(on_death))

/datum/element/death_icon_handling/Detach(obj/target)
	. = ..()
	UnregisterSignal(target, list(COMSIG_MOB_STATCHANG, COMSIG_LIVING_DEATH))

/**
 * Handles undoing anything that was perform on death.
 */
/datum/element/death_icon_handling/proc/on_death(mob/living/dead_mob, gibbed)
	SIGNAL_HANDLER
	dead_mob.icon_state = icon_dead
	if(flip_on_death)
		dead_mob.transform = transform.Turn(180)

/**
 * Handles undoing anything that was perform on death.
 */
/datum/element/death_icon_handling/proc/on_revive(mob/living/revived, full_heal)
	SIGNAL_HANDLER
	revived.icon_state = icon_living
	if (flip_on_death)
		revived.transform = transform.Turn(180)
