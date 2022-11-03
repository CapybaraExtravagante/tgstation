/datum/ai_controller/basic_controller/bot/clean
	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/cleanbot(),
		BB_CLEAN_BOT_TARGET = null,
		BB_IGNORE_LIST = list()
	)

	planning_subtrees = list(
		/datum/ai_planning_subtree/cleanbot_get_saluted,
		/datum/ai_planning_subtree/cleanbot_throw_foam,
		/datum/ai_planning_subtree/clean_target,
		/datum/ai_planning_subtree/core_bot_behaviors/watch_for_filth,
		/datum/ai_planning_subtree/watch_for_filth_idle
		)

	COOLDOWN_DECLARE(next_salute_check)

///Tries to move to and clean the specified target.
/datum/ai_planning_subtree/clean_target/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()

	var/mob/living/basic/bot/bot = controller.pawn

	if(controller.blackboard[BB_CLEAN_BOT_TARGET])
		controller.set_movement_target(controller.blackboard[BB_CLEAN_BOT_TARGET], /datum/ai_movement/basic_avoidance)
		if(bot.bot_cover_flags & BOT_COVER_EMAGGED)
			controller.queue_behavior(/datum/ai_behavior/evil_clean, BB_CLEAN_BOT_TARGET, BB_TARGETTING_DATUM)
		else
			controller.queue_behavior(/datum/ai_behavior/clean, BB_CLEAN_BOT_TARGET, BB_TARGETTING_DATUM)
		return SUBTREE_RETURN_FINISH_PLANNING

///Updates the blackboard with the current targets that can be targetted by the AI based on the specified janitor mode flags
/datum/ai_controller/basic_controller/bot/clean/proc/set_valid_targets(valid_targets)
	blackboard[BB_CLEAN_BOT_VALID_TARGETS] = valid_targets

///Look for filthy people while patrolling!
/datum/ai_planning_subtree/core_bot_behaviors/watch_for_filth/PatrolBehavior(datum/ai_controller/controller, delta_time)
	controller.queue_behavior(/datum/ai_behavior/move_to_next_patrol_point)
	controller.queue_behavior(/datum/ai_behavior/scan/constant, BB_CLEAN_BOT_TARGET, BB_TARGETTING_DATUM)

///Look for filthy things while idling too!
/datum/ai_planning_subtree/watch_for_filth_idle/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	controller.queue_behavior(/datum/ai_behavior/scan, BB_CLEAN_BOT_TARGET, BB_TARGETTING_DATUM)


///Commisioned clean bots can demand some respect!
/datum/ai_planning_subtree/cleanbot_get_saluted/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()

	var/datum/ai_controller/basic_controller/bot/clean/cleanbot_controller = controller

	if(cleanbot_controller.blackboard[BB_BOT_IS_COMMISSIONED] && COOLDOWN_FINISHED(cleanbot_controller, next_salute_check))
		cleanbot_controller.queue_behavior(/datum/ai_behavior/scan, BB_CLEAN_BOT_TARGET, BB_TARGETTING_DATUM)
		COOLDOWN_START(cleanbot_controller, next_salute_check, BOT_COMMISSIONED_SALUTE_DELAY)

///Emagged cleanbots spray foam all over!
/datum/ai_planning_subtree/cleanbot_throw_foam/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()

	var/mob/living/basic/bot/bot = controller.pawn

	if(bot.bot_cover_flags & BOT_COVER_EMAGGED)
		controller.queue_behavior(/datum/ai_behavior/spray_foam)

/datum/ai_behavior/clean
	required_distance = 1
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM


/datum/ai_behavior/clean/setup(datum/ai_controller/controller, target_key, targetting_datum_key)
	. = ..()
	var/mob/living/basic/bot/bot = controller.pawn
	bot.set_current_mode(BOT_CLEANING)
	RegisterSignal(bot, COMSIG_AINOTIFY_CLEANBOT_FINISH_CLEANING, .proc/on_finish_cleaning)

/datum/ai_behavior/clean/perform(delta_time, datum/ai_controller/controller, target_key, targetting_datum_key)
	. = ..()

	var/datum/targetting_datum/targetting_datum = controller.blackboard[targetting_datum_key]
	var/atom/target = controller.blackboard[target_key]

	if(!targetting_datum.can_attack(controller.pawn, target))
		finish_action(controller, FALSE)

	if(DT_PROB(5, delta_time))
		controller.pawn.audible_message("[controller.pawn] makes an excited beeping booping sound!")

	var/mob/living/living_pawn = controller.pawn

	if(controller.blackboard[BB_CLEAN_BOT_BUSY_CLEANING])
		return

	if(get_dist(controller.pawn, target) <= required_distance)
		living_pawn.UnarmedAttack(target, proximity_flag = TRUE) //Rather than check at every step of the way, let's check before we do an action, so we can rescan before the other bot.
		controller.blackboard[BB_CLEAN_BOT_BUSY_CLEANING] = TRUE

/datum/ai_behavior/clean/finish_action(datum/ai_controller/controller, succeeded, target_key, targetting_datum_key)
	. = ..()

	var/mob/living/basic/bot/bot = controller.pawn
	UnregisterSignal(bot, COMSIG_AINOTIFY_CLEANBOT_FINISH_CLEANING, .proc/on_finish_cleaning)
	bot.set_current_mode()

	if(!succeeded)
		var/atom/target = controller.blackboard[BB_CLEAN_BOT_TARGET]
		controller.blackboard[BB_IGNORE_LIST][WEAKREF(target)] = TRUE

	controller.blackboard[BB_CLEAN_BOT_BUSY_CLEANING] = FALSE
	controller.blackboard[BB_CLEAN_BOT_TARGET] = null

/datum/ai_behavior/clean/proc/on_finish_cleaning(datum/source, datum/ai_controller/controller)

	var/list/arguments = list(controller, TRUE)
	var/list/stored_arguments = controller.behavior_args[type]
	if(stored_arguments)
		arguments += stored_arguments

	finish_action(arglist(arguments))


/datum/ai_behavior/evil_clean
	required_distance = 1
	action_cooldown = 1.5 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT

/datum/ai_behavior/evil_clean/setup(datum/ai_controller/controller, target_key, targetting_datum_key)
	. = ..()
	var/mob/living/basic/bot/bot = controller.pawn
	bot.set_current_mode(BOT_CLEANING)

/datum/ai_behavior/evil_clean/perform(delta_time, datum/ai_controller/controller, target_key, targetting_datum_key)
	. = ..()

	var/mob/living/target = controller.blackboard[target_key]
	var/mob/living/living_pawn = controller.pawn
	var/datum/targetting_datum/targetting_datum = controller.blackboard[targetting_datum_key]


	if(!targetting_datum.can_attack(living_pawn, target))
		finish_action(controller, FALSE)

	living_pawn.UnarmedAttack(target, proximity_flag = TRUE) // Acid spray

/datum/ai_behavior/spray_foam
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/spray_foam/perform(delta_time, datum/ai_controller/controller, ...)
	. = ..()

	var/mob/living/living_pawn = controller.pawn


	if(isopenturf(living_pawn.loc) && DT_PROB(15, delta_time)) // Wets floors and spawns foam randomly
		if(prob(75))
			var/turf/open/current_floor =  living_pawn.loc
			if(istype(current_floor))
				current_floor.MakeSlippery(TURF_WET_WATER, min_wet_time = 20 SECONDS, wet_time_to_add = 15 SECONDS)
		else
			living_pawn.visible_message(span_danger("[living_pawn] whirs and bubbles violently, before releasing a plume of froth!"))
			new /obj/effect/particle_effect/fluid/foam(living_pawn.loc)
