/datum/ai_controller/basic_controller/slime
	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/allow_items(),
		BB_SLIME_ANGER = 0,
		BB_SLIME_RABID = FALSE,
		BB_SLIME_DISCIPLINE = 0,
		BB_SLIME_WAITING_PATIENCE = 0,
		BB_SLIME_CHASE_PATIENCE = 0,
	)

	ai_traits = STOP_MOVING_WHEN_PULLED
	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(
		/datum/ai_planning_subtree/tip_reaction,
		/datum/ai_planning_subtree/find_food,
		//attacking the food will eat it
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
		/datum/ai_planning_subtree/random_speech/cow,
	)


/datum/ai_controller/basic_controller/slime/proc/set_anger(new_value)
	blackboard[BB_SLIME_ANGER] = min(50, new_value)


/mob/living/basic/slime/proc/will_hunt(hunger = -1) // Check for being stopped from feeding and chasing
	if (docile)
		return FALSE
	if (hunger == 2 || rabid || attacked)
		return TRUE
	if (Leader)
		return FALSE
	if (holding_still)
		return FALSE
	return TRUE




/mob/living/basic/slime/proc/handle_targets(delta_time, times_fired)

	if(attacked > 0)
		attacked--

	if(Discipline > 0)

		if(Discipline >= 5 && rabid)
			if(DT_PROB(37, delta_time))
				rabid = 0

		if(DT_PROB(5, delta_time))
			Discipline--

	if(!client)
		if(!(mobility_flags & MOBILITY_MOVE))
			return

		if(buckled)
			return // if it's eating someone already, continue eating!

		if(Target)
			--target_patience
			if (target_patience <= 0 || SStun > world.time || Discipline || attacked || docile) // Tired of chasing or something draws out attention
				target_patience = 0
				set_target(null)

		if(AIproc && SStun > world.time)
			return

		var/hungry = 0 // determines if the slime is hungry

		if (nutrition < get_starve_nutrition())
			hungry = 2
		else if (nutrition < get_grow_nutrition() && DT_PROB(13, delta_time) || nutrition < get_hunger_nutrition())
			hungry = 1

		if(hungry == 2 && !client) // if a slime is starving, it starts losing its friends
			if(Friends.len > 0 && DT_PROB(0.5, delta_time))
				var/mob/nofriend = pick(Friends)
				add_friendship(nofriend, -1)

		if(!Target)
			if(will_hunt() && hungry || attacked || rabid) // Only add to the list if we need to
				var/list/targets = list()

				for(var/mob/living/L in view(7,src))

					if(isslime(L) || L.stat == DEAD) // Ignore other slimes and dead mobs
						continue

					if(L in Friends) // No eating friends!
						continue

					var/ally = FALSE
					for(var/F in faction)
						if(F == "neutral") //slimes are neutral so other mobs not target them, but they can target neutral mobs
							continue
						if(F in L.faction)
							ally = TRUE
							break
					if(ally)
						continue

					if(issilicon(L) && (rabid || attacked)) // They can't eat silicons, but they can glomp them in defence
						targets += L // Possible target found!

					if(locate(/mob/living/basic/slime) in L.buckled_mobs) // Only one slime can latch on at a time.
						continue

					targets += L // Possible target found!

				if(targets.len > 0)
					if(attacked || rabid || hungry == 2)
						set_target(targets[1]) // I am attacked and am fighting back or so hungry I don't even care
					else
						for(var/mob/living/carbon/C in targets)
							if(!Discipline && DT_PROB(2.5, delta_time))
								if(ishuman(C) || isalienadult(C))
									set_target(C)
									break

							if(islarva(C) || ismonkey(C))
								set_target(C)
								break

			if (Target)
				target_patience = rand(5, 7)
				if (is_adult)
					target_patience += 3

		if(!Target) // If we have no target, we are wandering or following orders
			if (Leader)
				if(holding_still)
					holding_still = max(holding_still - (0.5 * delta_time), 0)
				else if(!HAS_TRAIT(src, TRAIT_IMMOBILIZED) && isturf(loc))
					step_to(src, Leader)

			else if(hungry)
				if (holding_still)
					holding_still = max(holding_still - (0.5 * hungry * delta_time), 0)
				else if(!HAS_TRAIT(src, TRAIT_IMMOBILIZED) && isturf(loc) && prob(50))
					step(src, pick(GLOB.cardinals))

			else
				if(holding_still)
					holding_still = max(holding_still - (0.5 * delta_time), 0)
				else if (docile && pulledby)
					holding_still = 10
				else if(!HAS_TRAIT(src, TRAIT_IMMOBILIZED) && isturf(loc) && prob(33))
					step(src, pick(GLOB.cardinals))
		else if(!AIproc)
			INVOKE_ASYNC(src, PROC_REF(AIprocess))
