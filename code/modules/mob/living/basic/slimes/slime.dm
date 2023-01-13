/mob/living/basic/slime
	name = "grey baby slime (123)"
	icon = 'icons/mob/simple/slimes.dmi'
	icon_state = "grey baby slime"
	pass_flags = PASSTABLE | PASSGRILLE
	gender = NEUTER
	faction = list("slime","neutral")

	harm_intent_damage = 5
	icon_living = "grey baby slime"
	icon_dead = "grey baby slime dead"
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "shoos"
	response_disarm_simple = "shoo"
	response_harm_continuous = "stomps on"
	response_harm_simple = "stomp on"
	emote_see = list("jiggles", "bounces in place")
	speak_emote = list("blorbles")
	bubble_icon = "slime"
	initial_language_holder = /datum/language_holder/slime

	maxHealth = 150
	health = 150
	healable = 0
	melee_damage_lower = 5
	melee_damage_upper = 25
	see_in_dark = NIGHTVISION_FOV_RANGE

	verb_say = "blorbles"
	verb_ask = "inquisitively blorbles"
	verb_exclaim = "loudly blorbles"
	verb_yell = "loudly blorbles"

	// canstun and canknockdown don't affect slimes because they ignore stun and knockdown variables
	// for the sake of cleanliness, though, here they are.
	status_flags = CANUNCONSCIOUS|CANPUSH

	footstep_type = FOOTSTEP_MOB_SLIME

	///Whether the slime is an adult
	var/is_adult = FALSE
	/// the number of /obj/item/slime_extract's the slime has left inside
	var/cores = 1
	/// Chance of mutating, should be between 25 and 35
	var/mutation_chance = 30

	/// 1-10 controls how much electricity they are generating
	var/powerlevel = 0
	/// controls how long the slime has been overfed, if 10, grows or reproduces
	var/amount_grown = 0

	/// Identifying number for the slime
	var/identifier_number = 0

	///How hunger we currently are
	var/hunger_level = 0

	/*
	var/mob/living/Target = null // AI variable - tells the slime to hunt this down
	var/mob/living/Leader = null // AI variable - tells the slime to follow this person

	var/list/Friends = list() // A list of friends; they are not considered targets for feeding; passed down after splitting

	var/list/speech_buffer = list() // Last phrase said near it and person who said it

	*/

	var/mood = "" // To show its face
	/*
	var/mutator_used = FALSE //So you can't shove a dozen mutators into a single slime
	var/force_stasis = FALSE
	*/

	var/static/regex/slime_name_regex = new("\\w+ (baby|adult) slime \\(\\d+\\)")
	///////////TIME FOR SUBSPECIES

	var/colour = "grey"
	var/coretype = /obj/item/slime_extract/grey
	var/list/slime_mutation[4]

	var/static/list/slime_colours = list("rainbow", "grey", "purple", "metal", "orange",
	"blue", "dark blue", "dark purple", "yellow", "silver", "pink", "red",
	"gold", "green", "adamantine", "oil", "light pink", "bluespace",
	"cerulean", "sepia", "black", "pyrite")

	///////////CORE-CROSSING CODE

	var/effectmod //What core modification is being used.
	var/applied = 0 //How many extracts of the modtype have been applied.


/mob/living/basic/slime/Initialize(mapload, new_colour=colour, new_is_adult=FALSE)
	. = ..()
	AddElement(/datum/element/basic_body_temp_sensitive, 250, 350)

	var/datum/action/innate/slime/feed/F = new
	F.Grant(src)
	ADD_TRAIT(src, TRAIT_CANT_RIDE, INNATE_TRAIT)

	is_adult = new_is_adult

	if(is_adult)
		var/datum/action/innate/slime/reproduce/R = new
		R.Grant(src)
		health = 200
		maxHealth = 200
	else
		var/datum/action/innate/slime/evolve/E = new
		E.Grant(src)

	create_reagents(100)
	set_colour(new_colour)
	. = ..()
	set_nutrition(700)
	add_cell_sample()

	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)
	AddElement(/datum/element/soft_landing)

/mob/living/basic/slime/add_cell_sample()
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_SLIME, CELL_VIRUS_TABLE_GENERIC_MOB, 1, 5)

/mob/living/basic/slime/Destroy()
	for (var/A in actions)
		var/datum/action/AC = A
		AC.Remove(src)
	return ..()

/mob/living/basic/slime/create_reagents(max_vol, flags)
	. = ..()
	RegisterSignals(reagents, list(COMSIG_REAGENTS_NEW_REAGENT, COMSIG_REAGENTS_DEL_REAGENT), PROC_REF(on_reagent_change))
	RegisterSignal(reagents, COMSIG_PARENT_QDELETING, PROC_REF(on_reagents_del))

/// Handles removing signal hooks incase someone is crazy enough to reset the reagents datum.
/mob/living/basic/slime/proc/on_reagents_del(datum/reagents/reagents)
	SIGNAL_HANDLER
	UnregisterSignal(reagents, list(COMSIG_REAGENTS_NEW_REAGENT, COMSIG_REAGENTS_DEL_REAGENT, COMSIG_PARENT_QDELETING))
	return NONE

/mob/living/basic/slime/proc/set_colour(new_colour)
	colour = new_colour
	update_name()
	slime_mutation = mutation_table(colour)
	var/sanitizedcolour = replacetext(colour, " ", "")
	coretype = text2path("/obj/item/slime_extract/[sanitizedcolour]")
	regenerate_icons()

/mob/living/basic/slime/update_name()
	if(slime_name_regex.Find(name))
		identifier_number = rand(1, 1000)
		name = "[colour] [is_adult ? "adult" : "baby"] slime ([identifier_number])"
		real_name = name
	return ..()

/mob/living/basic/slime/proc/random_colour()
	set_colour(pick(slime_colours))

/mob/living/basic/slime/regenerate_icons()
	cut_overlays()
	var/icon_text = "[colour] [is_adult ? "adult" : "baby"] slime"
	icon_dead = "[icon_text] dead"
	if(stat != DEAD)
		icon_state = icon_text
		if(mood && !stat)
			add_overlay("aslime-[mood]")
	else
		icon_state = icon_dead
	..()

/**
 * Snowflake handling of reagent movespeed modifiers
 *
 * Should be moved to the reagents at some point in the future. As it is I'm in a hurry.
 */
/mob/living/basic/slime/proc/on_reagent_change(datum/reagents/holder, ...)
	SIGNAL_HANDLER
	remove_movespeed_modifier(/datum/movespeed_modifier/slime_reagentmod)
	var/amount = 0
	if(reagents.has_reagent(/datum/reagent/medicine/morphine)) // morphine slows slimes down
		amount = 2
	if(reagents.has_reagent(/datum/reagent/consumable/frostoil)) // Frostoil also makes them move VEEERRYYYYY slow
		amount = 5
	if(amount)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/slime_reagentmod, multiplicative_slowdown = amount)
	return NONE

/mob/living/basic/slime/updatehealth()
	. = ..()
	var/mod = 0
	if(!HAS_TRAIT(src, TRAIT_IGNOREDAMAGESLOWDOWN))
		var/health_deficiency = (maxHealth - health)
		if(health_deficiency >= 45)
			mod += (health_deficiency / 25)
		if(health <= 0)
			mod += 2
	add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/slime_healthmod, multiplicative_slowdown = mod)

/mob/living/basic/slime/adjust_bodytemperature()
	. = ..()
	var/mod = 0
	if(bodytemperature >= 330.23) // 135 F or 57.08 C
		mod = -1 // slimes become supercharged at high temperatures
	else if(bodytemperature < 283.222)
		mod = ((283.222 - bodytemperature) / 10) * 1.75
	if(mod)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/slime_tempmod, multiplicative_slowdown = mod)

/mob/living/basic/slime/ObjBump(obj/O)
	if(!client && powerlevel > 0)
		var/probab = 10
		switch(powerlevel)
			if(1 to 2)
				probab = 20
			if(3 to 4)
				probab = 30
			if(5 to 6)
				probab = 40
			if(7 to 8)
				probab = 60
			if(9)
				probab = 70
			if(10)
				probab = 95
		if(!prob(probab))
			return
		if(!istype(O, /obj/structure/window) && !istype(O, /obj/structure/grille))

		if(nutrition > get_hunger_nutrition() || Atkcool)
			return
		if (is_adult || prob(5))
			O.attack_slime(src)
			Atkcool = TRUE
			addtimer(VARSET_CALLBACK(src, Atkcool, FALSE), 4.5 SECONDS)

/mob/living/basic/slime/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	return 2

/mob/living/basic/slime/get_status_tab_items()
	. = ..()
	if(!docile)
		. += "Nutrition: [nutrition]/[get_max_nutrition()]"
	if(amount_grown >= SLIME_EVOLUTION_THRESHOLD)
		if(is_adult)
			. += "You can reproduce!"
		else
			. += "You can evolve!"

	switch(stat)
		if(HARD_CRIT, UNCONSCIOUS)
			. += "You are knocked out by high levels of BZ!"
		else
			. += "Power Level: [powerlevel]"


/mob/living/basic/slime/adjustFireLoss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced)
		amount = -abs(amount)
	return ..() //Heals them

/mob/living/basic/slime/bullet_act(obj/projectile/Proj, def_zone, piercing_hit = FALSE)
	attacked += 10
	if((Proj.damage_type == BURN))
		adjustBruteLoss(-abs(Proj.damage)) //fire projectiles heals slimes.
		Proj.on_hit(src, 0, piercing_hit)
	else
		. = ..(Proj)
	. = . || BULLET_ACT_BLOCK

/mob/living/basic/slime/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	powerlevel = 0 // oh no, the power!

/mob/living/basic/slime/MouseDrop(atom/movable/A as mob|obj)
	if(isliving(A) && A != src && usr == src)
		var/mob/living/Food = A
		if(CanFeedon(Food))
			Feedon(Food)
	return ..()

/mob/living/basic/slime/doUnEquip(obj/item/I, force, newloc, no_move, invdrop = TRUE, silent = FALSE)
	return

/mob/living/basic/slime/start_pulling(atom/movable/AM, state, force = move_force, supress_message = FALSE)
	return

/mob/living/basic/slime/attack_ui(slot, params)
	return

/mob/living/basic/slime/attack_slime(mob/living/basic/slime/M, list/modifiers)
	if(..()) //successful slime attack
		if(M == src)
			return
		if(buckled)
			Feedstop(silent = TRUE)
			visible_message(span_danger("[M] pulls [src] off!"), \
				span_danger("You pull [src] off!"))
			return
		attacked += 5
		if(nutrition >= 100) //steal some nutrition. negval handled in life()
			adjust_nutrition(-(50 + (40 * M.is_adult)))
			M.add_nutrition(50 + (40 * M.is_adult))
		if(health > 0)
			M.adjustBruteLoss(-10 + (-10 * M.is_adult))
			M.updatehealth()


/mob/living/basic/slime/attack_animal(mob/living/basic/user, list/modifiers)
	. = ..()
	if(.)
		attacked += 10


/mob/living/basic/slime/attack_paw(mob/living/carbon/human/user, list/modifiers)
	if(..()) //successful monkey bite.
		attacked += 10

/mob/living/basic/slime/attack_larva(mob/living/carbon/alien/larva/L, list/modifiers)
	if(..()) //successful larva bite.
		attacked += 10

/mob/living/basic/slime/attack_hulk(mob/living/carbon/human/user)
	. = ..()
	if(!.)
		return
	discipline_slime(user)


/mob/living/basic/slime/attack_hand(mob/living/carbon/human/user, list/modifiers)
	if(buckled)
		user.do_attack_animation(src, ATTACK_EFFECT_DISARM)
		if(buckled == user)
			if(prob(60))
				user.visible_message(span_warning("[user] attempts to wrestle \the [name] off!"), \
					span_danger("You attempt to wrestle \the [name] off!"))
				playsound(loc, 'sound/weapons/punchmiss.ogg', 25, TRUE, -1)

			else
				user.visible_message(span_warning("[user] manages to wrestle \the [name] off!"), \
					span_notice("You manage to wrestle \the [name] off!"))
				playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)

				discipline_slime(user)

		else
			if(prob(30))
				buckled.visible_message(span_warning("[user] attempts to wrestle \the [name] off of [buckled]!"), \
					span_warning("[user] attempts to wrestle \the [name] off of you!"))
				playsound(loc, 'sound/weapons/punchmiss.ogg', 25, TRUE, -1)

			else
				buckled.visible_message(span_warning("[user] manages to wrestle \the [name] off of [buckled]!"), \
					span_notice("[user] manage to wrestle \the [name] off of you!"))
				playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)

				discipline_slime(user)
	else
		if(stat == DEAD && surgeries.len)
			if(!user.combat_mode || LAZYACCESS(modifiers, RIGHT_CLICK))
				for(var/datum/surgery/operations as anything in surgeries)
					if(operations.next_step(user, modifiers))
						return TRUE
		if(..()) //successful attack
			attacked += 10

/mob/living/basic/slime/attack_alien(mob/living/carbon/alien/adult/user, list/modifiers)
	if(..()) //if harm or disarm intent.
		attacked += 10
		discipline_slime(user)


/mob/living/basic/slime/attackby(obj/item/W, mob/living/user, params)
	if(stat == DEAD && surgeries.len)
		var/list/modifiers = params2list(params)
		if(!user.combat_mode || (LAZYACCESS(modifiers, RIGHT_CLICK)))
			for(var/datum/surgery/operations as anything in surgeries)
				if(operations.next_step(user, modifiers))
					return TRUE
	if(istype(W, /obj/item/stack/sheet/mineral/plasma) && !stat) //Let's you feed slimes plasma.
		add_friendship(user, 1)
		to_chat(user, span_notice("You feed the slime the plasma. It chirps happily."))
		var/obj/item/stack/sheet/mineral/plasma/S = W
		S.use(1)
		return
	if(W.force > 0)
		attacked += 10
		if(prob(25))
			user.do_attack_animation(src)
			user.changeNext_move(CLICK_CD_MELEE)
			to_chat(user, span_danger("[W] passes right through [src]!"))
			return
		if(Discipline && prob(50)) // wow, buddy, why am I getting attacked??
			Discipline = 0
	if(W.force >= 3)
		var/force_effect = 2 * W.force
		if(is_adult)
			force_effect = round(W.force/2)
		if(prob(10 + force_effect))
			discipline_slime(user)
	if(istype(W, /obj/item/storage/bag/xeno))
		var/obj/item/storage/P = W
		if(!effectmod)
			to_chat(user, span_warning("The slime is not currently being mutated."))
			return
		var/hasOutput = FALSE //Have we outputted text?
		var/hasFound = FALSE //Have we found an extract to be added?
		for(var/obj/item/slime_extract/S in P.contents)
			if(S.effectmod == effectmod)
				P.atom_storage.attempt_remove(S, get_turf(src), silent = TRUE)
				qdel(S)
				applied++
				hasFound = TRUE
			if(applied >= SLIME_EXTRACT_CROSSING_REQUIRED)
				to_chat(user, span_notice("You feed the slime as many of the extracts from the bag as you can, and it mutates!"))
				playsound(src, 'sound/effects/attackblob.ogg', 50, TRUE)
				spawn_corecross()
				hasOutput = TRUE
				break
		if(!hasOutput)
			if(!hasFound)
				to_chat(user, span_warning("There are no extracts in the bag that this slime will accept!"))
			else
				to_chat(user, span_notice("You feed the slime some extracts from the bag."))
				playsound(src, 'sound/effects/attackblob.ogg', 50, TRUE)
		return
	..()

/mob/living/basic/slime/proc/spawn_corecross()
	var/static/list/crossbreeds = subtypesof(/obj/item/slimecross)
	visible_message(span_danger("[src] shudders, its mutated core consuming the rest of its body!"))
	playsound(src, 'sound/magic/smoke.ogg', 50, TRUE)
	var/crosspath
	for(var/X in crossbreeds)
		var/obj/item/slimecross/S = X
		if(initial(S.colour) == colour && initial(S.effect) == effectmod)
			crosspath = S
			break
	if(crosspath)
		new crosspath(loc)
	else
		visible_message(span_warning("The mutated core shudders, and collapses into a puddle, unable to maintain its form."))
	qdel(src)

/mob/living/basic/slime/proc/apply_water()
	adjustBruteLoss(rand(15,20))
	if(!client)
		if(Target) // Like cats
			set_target(null)
			++Discipline
	return

/mob/living/basic/slime/examine(mob/user)
	. = list("<span class='info'>This is [icon2html(src, user)] \a <EM>[src]</EM>!")
	if (stat == DEAD)
		. += span_deadsay("It is limp and unresponsive.")
	else
		if (stat == UNCONSCIOUS || stat == HARD_CRIT) // Slime stasis
			. += span_deadsay("It appears to be alive but unresponsive.")
		if (getBruteLoss())
			. += "<span class='warning'>"
			if (getBruteLoss() < 40)
				. += "It has some punctures in its flesh!"
			else
				. += "<B>It has severe punctures and tears in its flesh!</B>"
			. += "</span>\n"

		switch(powerlevel)
			if(2 to 3)
				. += "It is flickering gently with a little electrical activity."

			if(4 to 5)
				. += "It is glowing gently with moderate levels of electrical activity."

			if(6 to 9)
				. += span_warning("It is glowing brightly with high levels of electrical activity.")

			if(10)
				. += span_warning("<B>It is radiating with massive levels of electrical activity!</B>")

	. += "</span>"

/mob/living/basic/slime/proc/discipline_slime(mob/user)
	if(stat)
		return

	if(prob(80) && !client)
		Discipline++

		if(!is_adult)
			if(Discipline == 1)
				attacked = 0

	set_target(null)
	if(buckled)
		Feedstop(silent = TRUE) //we unbuckle the slime from the mob it latched onto.

	SStun = world.time + rand(20,60)

	Stun(3)
	if(user)
		step_away(src,user,15)

	addtimer(CALLBACK(src, PROC_REF(slime_move), user), 0.3 SECONDS)


/mob/living/basic/slime/proc/slime_move(mob/user)
	if(user)
		step_away(src,user,15)


/mob/living/basic/slime/pet
	docile = 1

/mob/living/basic/slime/get_mob_buckling_height(mob/seat)
	if(..())
		return 3

/mob/living/basic/slime/random/Initialize(mapload, new_colour, new_is_adult)
	. = ..(mapload, pick(slime_colours), prob(50))

/mob/living/basic/slime/proc/set_target(new_target)
	var/old_target = Target
	Target = new_target
	if(old_target && !SLIME_CARES_ABOUT(old_target))
		UnregisterSignal(old_target, COMSIG_PARENT_QDELETING)
	if(Target)
		RegisterSignal(Target, COMSIG_PARENT_QDELETING, PROC_REF(clear_memories_of), override = TRUE)

/mob/living/basic/slime/proc/set_leader(new_leader)
	var/old_leader = Leader
	Leader = new_leader
	if(old_leader && !SLIME_CARES_ABOUT(old_leader))
		UnregisterSignal(old_leader, COMSIG_PARENT_QDELETING)
	if(Leader)
		RegisterSignal(Leader, COMSIG_PARENT_QDELETING, PROC_REF(clear_memories_of), override = TRUE)

/mob/living/basic/slime/proc/set_friends(new_buds)
	clear_friends()
	for(var/mob/friend as anything in new_buds)
		set_friendship(friend, new_buds[friend])

/mob/living/basic/slime/proc/clear_friends()
	for(var/mob/friend as anything in Friends)
		remove_friend(friend)

#undef SLIME_CARES_ABOUT

	var/SStun = 0 // stun variable


/mob/living/basic/slime/Life(delta_time = SSMOBS_DT, times_fired)
	if (notransform)
		return
	. = ..()
	if(!.)
		return
	if(buckled)
		handle_feeding(delta_time, times_fired)
	if(stat) // Slimes in stasis don't lose nutrition, don't change mood and don't respond to speech
		return
	handle_nutrition(delta_time, times_fired)
	if(QDELETED(src)) // Stop if the slime split during handle_nutrition()
		return
	reagents.remove_all(0.5 * REAGENTS_METABOLISM * reagents.reagent_list.len * delta_time) //Slimes are such snowflakes

	handle_targets(delta_time, times_fired)
	if(ckey)
		return
	handle_mood(delta_time, times_fired)
	handle_speech(delta_time, times_fired)


// Unlike most of the simple animals, slimes support UNCONSCIOUS. This is an ugly hack.
/mob/living/basic/slime/update_stat()
	switch(stat)
		if(UNCONSCIOUS, HARD_CRIT)
			if(health > 0)
				return
	return ..()


/mob/living/basic/slime/proc/AIprocess()  // the master AI process

	if(AIproc || stat || client)
		return




	AIproc = 1

	while(AIproc && stat != DEAD && (attacked || hungry || rabid || buckled))
		if(!(mobility_flags & MOBILITY_MOVE)) //also covers buckling. Not sure why buckled is in the while condition if we're going to immediately break, honestly
			break

		if(!Target || client)
			break

		if(Target.health <= -70 || Target.stat == DEAD)
			set_target(null)
			AIproc = 0
			break

		if(Target)
			if(locate(/mob/living/basic/slime) in Target.buckled_mobs)
				set_target(null)
				AIproc = 0
				break
			if(!AIproc)
				break

			if(Target in view(1,src))
				if(!CanFeedon(Target)) //If they're not able to be fed upon, ignore them.
					if(!Atkcool)
						Atkcool = TRUE
						addtimer(VARSET_CALLBACK(src, Atkcool, FALSE), 4.5 SECONDS)

						if(Target.Adjacent(src))
							Target.attack_slime(src)
					break
				if((Target.body_position == STANDING_UP) && prob(80))

					if(Target.client && Target.health >= 20)
						if(!Atkcool)
							Atkcool = TRUE
							addtimer(VARSET_CALLBACK(src, Atkcool, FALSE), 4.5 SECONDS)

							if(Target.Adjacent(src))
								Target.attack_slime(src)

					else
						if(!Atkcool && Target.Adjacent(src))
							Feedon(Target)

				else
					if(!Atkcool && Target.Adjacent(src))
						Feedon(Target)

			else if(Target in view(7, src))
				if(!Target.Adjacent(src))
				// Bug of the month candidate: slimes were attempting to move to target only if it was directly next to them, which caused them to target things, but not approach them
					step_to(src, Target)
			else
				set_target(null)
				AIproc = 0
				break

		var/sleeptime = cached_multiplicative_slowdown
		if(sleeptime <= 0)
			sleeptime = 1

		sleep(sleeptime + 2) // this is about as fast as a player slime can go

	AIproc = 0

/mob/living/basic/slime/handle_environment(datum/gas_mixture/environment, delta_time, times_fired)
	var/loc_temp = get_temperature(environment)
	var/divisor = 10 /// The divisor controls how fast body temperature changes, lower causes faster changes

	var/temp_delta = loc_temp - bodytemperature
	if(abs(temp_delta) > 50) // If the difference is great, reduce the divisor for faster stabilization
		divisor = 5

	if(temp_delta < 0) // It is cold here
		if(!on_fire) // Do not reduce body temp when on fire
			adjust_bodytemperature(clamp((temp_delta / divisor) * delta_time, temp_delta, 0))
	else // This is a hot place
		adjust_bodytemperature(clamp((temp_delta / divisor) * delta_time, 0, temp_delta))

	if(bodytemperature < (T0C + 5)) // start calculating temperature damage etc
		if(bodytemperature <= (T0C - 40)) // stun temperature
			ADD_TRAIT(src, TRAIT_IMMOBILIZED, SLIME_COLD)
		else
			REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, SLIME_COLD)

		if(bodytemperature <= (T0C - 50)) // hurt temperature
			if(bodytemperature <= 50) // sqrting negative numbers is bad
				adjustBruteLoss(100 * delta_time)
			else
				adjustBruteLoss(round(sqrt(bodytemperature)) * delta_time)
	else
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, SLIME_COLD)

	if(stat != DEAD)
		var/bz_percentage =0
		if(environment.gases[/datum/gas/bz])
			bz_percentage = environment.gases[/datum/gas/bz][MOLES] / environment.total_moles()
		var/stasis = (bz_percentage >= 0.05 && bodytemperature < (T0C + 100)) || force_stasis

		switch(stat)
			if(CONSCIOUS)
				if(stasis)
					to_chat(src, span_danger("Nerve gas in the air has put you in stasis!"))
					set_stat(UNCONSCIOUS)
					powerlevel = 0
					rabid = FALSE
					regenerate_icons()
			if(UNCONSCIOUS, HARD_CRIT)
				if(!stasis)
					to_chat(src, span_notice("You wake up from the stasis."))
					set_stat(CONSCIOUS)
					regenerate_icons()

	updatehealth()


/mob/living/basic/slime/handle_status_effects(delta_time, times_fired)
	..()
	if(!stat && DT_PROB(16, delta_time))
		adjustBruteLoss(-0.5 * delta_time)

/mob/living/basic/slime/proc/handle_feeding(delta_time, times_fired)
	if(!ismob(buckled))
		return
	var/mob/M = buckled

	if(stat)
		Feedstop(silent = TRUE)

	if(M.stat == DEAD) // our victim died
		if(!client)
			if(!rabid && !attacked)
				var/mob/last_to_hurt = M.LAssailant?.resolve()
				if(last_to_hurt && last_to_hurt != M)
					if(DT_PROB(30, delta_time))
						add_friendship(last_to_hurt, 1)
		else
			to_chat(src, "<i>This subject does not have a strong enough life energy anymore...</i>")

		if(M.client && ishuman(M))
			if(DT_PROB(61, delta_time))
				rabid = 1 //we go rabid after finishing to feed on a human with a client.

		Feedstop()
		return

	if(iscarbon(M))
		var/mob/living/carbon/C = M
		C.adjustCloneLoss(rand(2, 4) * 0.5 * delta_time)
		C.adjustToxLoss(rand(1, 2) * 0.5 * delta_time)

		if(DT_PROB(5, delta_time) && C.client)
			to_chat(C, "<span class='userdanger'>[pick("You can feel your body becoming weak!", \
			"You feel like you're about to die!", \
			"You feel every part of your body screaming in agony!", \
			"A low, rolling pain passes through your body!", \
			"Your body feels as if it's falling apart!", \
			"You feel extremely weak!", \
			"A sharp, deep pain bathes every inch of your body!")]</span>")

	else if(isanimal(M))
		var/mob/living/basic/SA = M

		var/totaldamage = 0 //total damage done to this unfortunate animal
		totaldamage += SA.adjustCloneLoss(rand(2, 4) * 0.5 * delta_time)
		totaldamage += SA.adjustToxLoss(rand(1, 2) * 0.5 * delta_time)

		if(totaldamage <= 0) //if we did no(or negative!) damage to it, stop
			Feedstop(0, 0)
			return

	else
		Feedstop(0, 0)
		return

	add_nutrition((rand(7, 15) * 0.5 * delta_time * CONFIG_GET(number/damage_multiplier)))

	//Heal yourself.
	adjustBruteLoss(-1.5 * delta_time)

/mob/living/basic/slime/proc/handle_nutrition(delta_time, times_fired)

	if(docile) //God as my witness, I will never go hungry again
		set_nutrition(700) //fuck you for using the base nutrition var
		return

	if(DT_PROB(7.5, delta_time))
		adjust_nutrition(-0.5 * (1 + is_adult) * delta_time)

	if(nutrition <= 0)
		set_nutrition(0)
		if(DT_PROB(50, delta_time))
			adjustBruteLoss(rand(0,5))

	else if (nutrition >= get_grow_nutrition() && amount_grown < SLIME_EVOLUTION_THRESHOLD)
		adjust_nutrition(-10 * delta_time)
		amount_grown++
		update_mob_action_buttons()

	if(amount_grown >= SLIME_EVOLUTION_THRESHOLD && !buckled && !Target && !ckey)
		if(is_adult && loc.AllowDrop())
			Reproduce()
		else
			Evolve()

/mob/living/basic/slime/proc/add_nutrition(nutrition_to_add = 0)
	set_nutrition(min((nutrition + nutrition_to_add), get_max_nutrition()))
	if(nutrition >= get_grow_nutrition())
		if(powerlevel<10)
			if(prob(30-powerlevel*2))
				powerlevel++
	else if(nutrition >= get_hunger_nutrition() + 100) //can't get power levels unless you're a bit above hunger level.
		if(powerlevel<5)
			if(prob(25-powerlevel*5))
				powerlevel++


/mob/living/basic/slime/proc/set_nutrition(change)
	. = ..()
	if (nutrition < get_starve_nutrition())
		hungry = 2
	else if (nutrition < get_grow_nutrition() && prob(25) || nutrition < get_hunger_nutrition())
		hungry = 1

/mob/living/basic/slime/handle_automated_movement()
	return //slime random movement is currently handled in handle_targets()

/mob/living/basic/slime/handle_automated_speech()
	return //slime random speech is currently handled in handle_speech()

/mob/living/basic/slime/proc/handle_mood(delta_time, times_fired)
	var/newmood = ""
	if (rabid || attacked)
		newmood = "angry"
	else if (docile)
		newmood = ":3"
	else if (Target)
		newmood = "mischievous"

	if (!newmood)
		if (Discipline && DT_PROB(13, delta_time))
			newmood = "pout"
		else if (DT_PROB(0.5, delta_time))
			newmood = pick("sad", ":3", "pout")

	if ((mood == "sad" || mood == ":3" || mood == "pout") && !newmood)
		if(DT_PROB(50, delta_time))
			newmood = mood

	if (newmood != mood) // This is so we don't redraw them every time
		mood = newmood
		regenerate_icons()

/mob/living/basic/slime/proc/handle_speech(delta_time, times_fired)
	//Speech understanding starts here
	var/to_say
	if (speech_buffer.len > 0)
		var/who = speech_buffer[1] // Who said it?
		var/phrase = speech_buffer[2] // What did they say?
		if ((findtext(phrase, num2text(number)) || findtext(phrase, "slimes"))) // Talking to us
			if (findtext(phrase, "hello") || findtext(phrase, "hi"))
				to_say = pick("Hello...", "Hi...")
			else if (findtext(phrase, "follow"))
				if (Leader)
					if (Leader == who) // Already following him
						to_say = pick("Yes...", "Lead...", "Follow...")
					else if (Friends[who] > Friends[Leader]) // VIVA
						set_leader(who)
						to_say = "Yes... I follow [who]..."
					else
						to_say = "No... I follow [Leader]..."
				else
					if (Friends[who] >= SLIME_FRIENDSHIP_FOLLOW)
						set_leader(who)
						to_say = "I follow..."
					else // Not friendly enough
						to_say = pick("No...", "I no follow...")
			else if (findtext(phrase, "stop"))
				if (buckled) // We are asked to stop feeding
					if (Friends[who] >= SLIME_FRIENDSHIP_STOPEAT)
						Feedstop()
						set_target(null)
						if (Friends[who] < SLIME_FRIENDSHIP_STOPEAT_NOANGRY)
							add_friendship(who, -1)
							to_say = "Grrr..." // I'm angry but I do it
						else
							to_say = "Fine..."
				else if (Target) // We are asked to stop chasing
					if (Friends[who] >= SLIME_FRIENDSHIP_STOPCHASE)
						set_target(null)
						if (Friends[who] < SLIME_FRIENDSHIP_STOPCHASE_NOANGRY)
							add_friendship(who, -1)
							to_say = "Grrr..." // I'm angry but I do it
						else
							to_say = "Fine..."
				else if (Leader) // We are asked to stop following
					if (Leader == who)
						to_say = "Yes... I stay..."
						set_leader(null)
					else
						if (Friends[who] > Friends[Leader])
							set_leader(null)
							to_say = "Yes... I stop..."
						else
							to_say = "No... keep follow..."
			else if (findtext(phrase, "stay"))
				if (Leader)
					if (Leader == who)
						holding_still = Friends[who] * 10
						to_say = "Yes... stay..."
					else if (Friends[who] > Friends[Leader])
						holding_still = (Friends[who] - Friends[Leader]) * 10
						to_say = "Yes... stay..."
					else
						to_say = "No... keep follow..."
				else
					if (Friends[who] >= SLIME_FRIENDSHIP_STAY)
						holding_still = Friends[who] * 10
						to_say = "Yes... stay..."
					else
						to_say = "No... won't stay..."
			else if (findtext(phrase, "attack"))
				if (rabid && prob(20))
					set_target(who)
					AIprocess() //Wake up the slime's Target AI, needed otherwise this doesn't work
					to_say = "ATTACK!?!?"
				else if (Friends[who] >= SLIME_FRIENDSHIP_ATTACK)
					for (var/mob/living/L in view(7,src)-list(src,who))
						if (findtext(phrase, lowertext(L.name)))
							if (isslime(L))
								to_say = "NO... [L] slime friend"
								add_friendship(who, -1) //Don't ask a slime to attack its friend
							else if(!Friends[L] || Friends[L] < 1)
								set_target(L)
								AIprocess()//Wake up the slime's Target AI, needed otherwise this doesn't work
								to_say = "Ok... I attack [Target]"
							else
								to_say = "No... like [L] ..."
								add_friendship(who, -1) //Don't ask a slime to attack its friend
							break
				else
					to_say = "No... no listen"

		speech_buffer = list()

	//Speech starts here
	if (to_say)
		say (to_say)
	else if(DT_PROB(0.5, delta_time))
		emote(pick("bounce","sway","light","vibrate","jiggle"))
	else
		var/t = 10
		var/slimes_near = 0
		var/dead_slimes = 0
		var/friends_near = list()
		for (var/mob/living/L in view(7,src))
			if(isslime(L) && L != src)
				++slimes_near
				if (L.stat == DEAD)
					++dead_slimes
			if (L in Friends)
				t += 20
				friends_near += L
		if (nutrition < get_hunger_nutrition())
			t += 10
		if (nutrition < get_starve_nutrition())
			t += 10
		if (DT_PROB(1, delta_time) && prob(t))
			var/phrases = list()
			if (Target)
				phrases += "[Target]... look yummy..."
			if (nutrition < get_starve_nutrition())
				phrases += "So... hungry..."
				phrases += "Very... hungry..."
				phrases += "Need... food..."
				phrases += "Must... eat..."
			else if (nutrition < get_hunger_nutrition())
				phrases += "Hungry..."
				phrases += "Where food?"
				phrases += "I want to eat..."
			phrases += "Rawr..."
			phrases += "Blop..."
			phrases += "Blorble..."
			if (rabid || attacked)
				phrases += "Hrr..."
				phrases += "Nhuu..."
				phrases += "Unn..."
			if (mood == ":3")
				phrases += "Purr..."
			if (attacked)
				phrases += "Grrr..."
			if (bodytemperature < T0C)
				phrases += "Cold..."
			if (bodytemperature < T0C - 30)
				phrases += "So... cold..."
				phrases += "Very... cold..."
			if (bodytemperature < T0C - 50)
				phrases += "..."
				phrases += "C... c..."
			if (buckled)
				phrases += "Nom..."
				phrases += "Yummy..."
			if (powerlevel > 3)
				phrases += "Bzzz..."
			if (powerlevel > 5)
				phrases += "Zap..."
			if (powerlevel > 8)
				phrases += "Zap... Bzz..."
			if (mood == "sad")
				phrases += "Bored..."
			if (slimes_near)
				phrases += "Slime friend..."
			if (slimes_near > 1)
				phrases += "Slime friends..."
			if (dead_slimes)
				phrases += "What happened?"
			if (!slimes_near)
				phrases += "Lonely..."
			for (var/M in friends_near)
				phrases += "[M]... friend..."
				if (nutrition < get_hunger_nutrition())
					phrases += "[M]... feed me..."
			if(!stat)
				say (pick(phrases))

/mob/living/basic/slime/proc/get_max_nutrition() // Can't go above it
	if (is_adult)
		return 1200
	else
		return 1000

/mob/living/basic/slime/proc/get_grow_nutrition() // Above it we grow, below it we can eat
	if (is_adult)
		return 1000
	else
		return 800

/mob/living/basic/slime/proc/get_hunger_nutrition() // Below it we will always eat
	if (is_adult)
		return 600
	else
		return 500

/mob/living/basic/slime/proc/get_starve_nutrition() // Below it we will eat before everything else
	if(is_adult)
		return 300
	else
		return 200


