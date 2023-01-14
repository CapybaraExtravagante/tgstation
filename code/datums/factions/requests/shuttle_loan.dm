#define HIJACK_SYNDIE "syndies"
#define RUSKY_PARTY "ruskies"
#define SPIDER_GIFT "spiders"
#define DEPARTMENT_RESUPPLY "resupplies"
#define ANTIDOTE_NEEDED "disease"
#define PIZZA_DELIVERY "pizza"
#define ITS_HIP_TO "bees"
#define MY_GOD_JC "bomb"
#define PAPERS_PLEASE "paperwork"

/datum/faction_request/shuttle_loan
	title = "Shuttle Loan"
	var/dispatch_type = "none"
	var/list/shuttle_loan_offers = list(
		ANTIDOTE_NEEDED,
		DEPARTMENT_RESUPPLY,
		HIJACK_SYNDIE,
		ITS_HIP_TO,
		MY_GOD_JC,
		PIZZA_DELIVERY,
		RUSKY_PARTY,
		SPIDER_GIFT,
		PAPERS_PLEASE,
	)
	var/dispatched = FALSE
	var/supply_points_reward = 1000
	var/reputation_reward = 2
	var/thanks_msg = "The cargo shuttle should return in five minutes. Have some supply points for your trouble."
	var/loan_type //for logging

/datum/faction_request/shuttle_loan/on_completion(silent)
	. = ..()
	var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
	if(D)
		D.adjust_money(supply_points_reward)
	requesting_faction.add_relationship(reputation_reward)

/datum/faction_request/shuttle_loan/get_explanation()
	var/message
	if(completed)
		if(dispatch_type == PAPERS_PLEASE)
			message += "Thanks for taking this paperwork off our hands, be sure to send in the papers to us through your cargo shuttle for some profit"
		else
			message += "Thank you for letting us use your shuttle."
		return
	else if(accepted)
		return "Use your cargo console to send the shuttle our way. Once that is done the request can be completed in here"
	else
		switch(dispatch_type)
			if(HIJACK_SYNDIE)
				message += "The syndicate are trying to infiltrate your station. If you let them hijack your cargo shuttle, you'll save us a headache."
			if(RUSKY_PARTY)
				message += "A group of angry Russians want to have a party. Can you send them your cargo shuttle then make them disappear?"
			if(SPIDER_GIFT)
				message += "The Spider Clan has sent us a mysterious gift. Can we ship it to you to see what's inside?"
			if(DEPARTMENT_RESUPPLY)
				message += "Seems we've ordered doubles of our department resupply packages this month. Can we send them to you?"
			if(ANTIDOTE_NEEDED)
				message += "Your station has been chosen for an epidemiological research project. Send us your cargo shuttle to receive your research samples."
			if(PIZZA_DELIVERY)
				message += "It looks like a neighbouring station accidentally delivered their pizza to you instead."
			if(ITS_HIP_TO)
				message += "One of our freighters carrying a bee shipment has been attacked by eco-terrorists. Can you clean up the mess for us?"
			if(MY_GOD_JC)
				message += "We have discovered an active Syndicate bomb near our VIP shuttle's fuel lines. If you feel up to the task, we will pay you for defusing it."
			if(PAPERS_PLEASE)
				message += "A neighboring station needs some help handling some paperwork. Could you help process it for us?"

	if(supply_points_reward)
		message += " [supply_points_reward] will be deposited into your cargo funds for completing this request."
	if(supply_points_reward)
		message += " [reputation_reward] reputation will be gained from completing this request."
	return message

/datum/faction_request/shuttle_loan/on_request_created()
	. = ..()
	dispatch_type = pick(shuttle_loan_offers) //Pick a loan to offer
	SSshuttle.shuttle_loan = src
	switch(dispatch_type)
		if(DEPARTMENT_RESUPPLY)
			thanks_msg = "The cargo shuttle should return in five minutes."
			supply_points_reward = 0
		if(PIZZA_DELIVERY)
			thanks_msg = "The cargo shuttle should return in five minutes."
			supply_points_reward = 0
		if(ITS_HIP_TO)
			supply_points_reward = 20000 //Toxin bees can be unbeelievably lethal
		if(MY_GOD_JC)
			thanks_msg = "Live explosive ordnance incoming via supply shuttle. Evacuating cargo bay is recommended."
			supply_points_reward = 45000 //If you mess up, people die and the shuttle gets turned into swiss cheese
		if(PAPERS_PLEASE)
			thanks_msg = "The cargo shuttle should return in five minutes. Payment will be rendered when the paperwork is processed and returned."
			supply_points_reward = 0 //Payout is made when the stamped papers are returned

/datum/faction_request/shuttle_loan/proc/loan_shuttle()
	priority_announce(thanks_msg, "Cargo shuttle commandeered by CentCom.")

	dispatched = TRUE

	SSshuttle.supply.mode = SHUTTLE_CALL
	SSshuttle.supply.destination = SSshuttle.getDock("cargo_home")
	SSshuttle.supply.setTimer(3000)

	switch(dispatch_type)
		if(HIJACK_SYNDIE)
			SSshuttle.centcom_message += "Syndicate hijack team incoming."
			loan_type = "Syndicate boarding party"
		if(RUSKY_PARTY)
			SSshuttle.centcom_message += "Partying Russians incoming."
			loan_type = "Russian party squad"
		if(SPIDER_GIFT)
			SSshuttle.centcom_message += "Spider Clan gift incoming."
			loan_type = "Shuttle full of spiders"
		if(DEPARTMENT_RESUPPLY)
			SSshuttle.centcom_message += "Department resupply incoming."
			loan_type = "Resupply packages"
		if(ANTIDOTE_NEEDED)
			SSshuttle.centcom_message += "Virus samples incoming."
			loan_type = "Virus shuttle"
		if(PIZZA_DELIVERY)
			SSshuttle.centcom_message += "Pizza delivery for [station_name()]"
			loan_type = "Pizza delivery"
		if(ITS_HIP_TO)
			SSshuttle.centcom_message += "Biohazard cleanup incoming."
			loan_type = "Shuttle full of bees"
		if(MY_GOD_JC)
			SSshuttle.centcom_message += "Live explosive ordnance incoming. Exercise extreme caution."
			loan_type = "Shuttle with a ticking bomb"
		if(PAPERS_PLEASE)
			SSshuttle.centcom_message += "Paperwork incoming."
			loan_type = "Paperwork shipment"

	log_game("Shuttle loan event firing with type '[loan_type]'.")
	RegisterSignal(SSshuttle.supply, COMSIG_SHUTTLE_DOCKED, PROC_REF(shuttle_arrived))

/datum/faction_request/shuttle_loan/proc/shuttle_arrived()
	if(SSshuttle.shuttle_loan && SSshuttle.shuttle_loan.dispatched)
		//make sure the shuttle was dispatched in time
		SSshuttle.shuttle_loan = null
		UnregisterSignal(SSshuttle.supply, COMSIG_SHUTTLE_DOCKED)

		var/list/empty_shuttle_turfs = list()
		var/list/area/shuttle/shuttle_areas = SSshuttle.supply.shuttle_areas
		for(var/place in shuttle_areas)
			var/area/shuttle/shuttle_area = place
			for(var/turf/open/floor/T in shuttle_area)
				if(T.is_blocked_turf())
					continue
				empty_shuttle_turfs += T
		if(!empty_shuttle_turfs.len)
			return

		var/list/shuttle_spawns = list()
		switch(dispatch_type)
			if(HIJACK_SYNDIE)
				var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/emergency/specialops]
				pack.generate(pick_n_take(empty_shuttle_turfs))

				shuttle_spawns.Add(/mob/living/basic/syndicate/ranged/infiltrator)
				shuttle_spawns.Add(/mob/living/basic/syndicate/ranged/infiltrator)
				if(prob(75))
					shuttle_spawns.Add(/mob/living/basic/syndicate/ranged/infiltrator)
				if(prob(50))
					shuttle_spawns.Add(/mob/living/basic/syndicate/ranged/infiltrator)

			if(RUSKY_PARTY)
				var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/service/party]
				pack.generate(pick_n_take(empty_shuttle_turfs))

				shuttle_spawns.Add(/mob/living/simple_animal/hostile/russian)
				shuttle_spawns.Add(/mob/living/simple_animal/hostile/russian/ranged) //drops a mateba
				shuttle_spawns.Add(/mob/living/simple_animal/hostile/bear/russian)
				if(prob(75))
					shuttle_spawns.Add(/mob/living/simple_animal/hostile/russian)
				if(prob(50))
					shuttle_spawns.Add(/mob/living/simple_animal/hostile/bear/russian)

			if(SPIDER_GIFT)
				var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/emergency/specialops]
				pack.generate(pick_n_take(empty_shuttle_turfs))

				shuttle_spawns.Add(/mob/living/simple_animal/hostile/giant_spider)
				shuttle_spawns.Add(/mob/living/simple_animal/hostile/giant_spider)
				shuttle_spawns.Add(/mob/living/simple_animal/hostile/giant_spider/nurse)
				if(prob(50))
					shuttle_spawns.Add(/mob/living/simple_animal/hostile/giant_spider/hunter)

				var/turf/T = pick_n_take(empty_shuttle_turfs)

				new /obj/effect/decal/remains/human(T)
				new /obj/item/clothing/shoes/jackboots/fast(T)
				new /obj/item/clothing/mask/balaclava(T)

				for(var/i in 1 to 5)
					T = pick_n_take(empty_shuttle_turfs)
					new /obj/structure/spider/stickyweb(T)

			if(ANTIDOTE_NEEDED)
				var/obj/effect/mob_spawn/corpse/human/assistant/infected_assistant = pick(/obj/effect/mob_spawn/corpse/human/assistant/beesease_infection, /obj/effect/mob_spawn/corpse/human/assistant/brainrot_infection, /obj/effect/mob_spawn/corpse/human/assistant/spanishflu_infection)
				var/turf/T
				for(var/i in 1 to 10)
					if(prob(15))
						shuttle_spawns.Add(/obj/item/reagent_containers/cup/bottle)
					else if(prob(15))
						shuttle_spawns.Add(/obj/item/reagent_containers/syringe)
					else if(prob(25))
						shuttle_spawns.Add(/obj/item/shard)
					T = pick_n_take(empty_shuttle_turfs)
					new infected_assistant(T)
				shuttle_spawns.Add(/obj/structure/closet/crate)
				shuttle_spawns.Add(/obj/item/reagent_containers/cup/bottle/pierrot_throat)
				shuttle_spawns.Add(/obj/item/reagent_containers/cup/bottle/magnitis)

			if(DEPARTMENT_RESUPPLY)
				var/list/crate_types = list(
					/datum/supply_pack/emergency/equipment,
					/datum/supply_pack/security/supplies,
					/datum/supply_pack/organic/food,
					/datum/supply_pack/emergency/weedcontrol,
					/datum/supply_pack/engineering/tools,
					/datum/supply_pack/engineering/engiequipment,
					/datum/supply_pack/science/robotics,
					/datum/supply_pack/science/plasma,
					/datum/supply_pack/medical/supplies
					)
				for(var/crate in crate_types)
					var/datum/supply_pack/pack = SSshuttle.supply_packs[crate]
					pack.generate(pick_n_take(empty_shuttle_turfs))

				for(var/i in 1 to 5)
					var/decal = pick(/obj/effect/decal/cleanable/food/flour, /obj/effect/decal/cleanable/robot_debris, /obj/effect/decal/cleanable/oil)
					new decal(pick_n_take(empty_shuttle_turfs))
			if(PIZZA_DELIVERY)
				var/naughtypizza = list(/obj/item/pizzabox/bomb,/obj/item/pizzabox/margherita/robo) //oh look another blaklist, for pizza nonetheless!
				var/nicepizza = list(/obj/item/pizzabox/margherita, /obj/item/pizzabox/meat, /obj/item/pizzabox/vegetable, /obj/item/pizzabox/mushroom)
				for(var/i in 1 to 6)
					shuttle_spawns.Add(pick(prob(5) ? naughtypizza : nicepizza))
			if(ITS_HIP_TO)
				var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/organic/hydroponics/beekeeping_fullkit]
				pack.generate(pick_n_take(empty_shuttle_turfs))

				shuttle_spawns.Add(/obj/effect/mob_spawn/corpse/human/bee_terrorist)
				shuttle_spawns.Add(/obj/effect/mob_spawn/corpse/human/cargo_tech)
				shuttle_spawns.Add(/obj/effect/mob_spawn/corpse/human/cargo_tech)
				shuttle_spawns.Add(/obj/effect/mob_spawn/corpse/human/nanotrasensoldier)
				shuttle_spawns.Add(/obj/item/gun/ballistic/automatic/pistol/no_mag)
				shuttle_spawns.Add(/obj/item/gun/ballistic/automatic/pistol/m1911/no_mag)
				shuttle_spawns.Add(/obj/item/honey_frame)
				shuttle_spawns.Add(/obj/item/honey_frame)
				shuttle_spawns.Add(/obj/item/honey_frame)
				shuttle_spawns.Add(/obj/structure/beebox/unwrenched)
				shuttle_spawns.Add(/obj/item/queen_bee/bought)
				shuttle_spawns.Add(/obj/structure/closet/crate/hydroponics)

				for(var/i in 1 to 8)
					shuttle_spawns.Add(/mob/living/simple_animal/hostile/bee/toxin)

				for(var/i in 1 to 5)
					var/decal = pick(/obj/effect/decal/cleanable/blood, /obj/effect/decal/cleanable/insectguts)
					new decal(pick_n_take(empty_shuttle_turfs))

				for(var/i in 1 to 10)
					var/casing = /obj/item/ammo_casing/spent
					new casing(pick_n_take(empty_shuttle_turfs))

			if(MY_GOD_JC)
				shuttle_spawns.Add(/obj/machinery/syndicatebomb/shuttle_loan)
				if(prob(95))
					shuttle_spawns.Add(/obj/item/paper/fluff/cargo/bomb)
				else
					shuttle_spawns.Add(/obj/item/paper/fluff/cargo/bomb/allyourbase)

			if(PAPERS_PLEASE)
				shuttle_spawns += subtypesof(/obj/item/paperwork) - typesof(/obj/item/paperwork/photocopy) - typesof(/obj/item/paperwork/ancient)

		var/false_positive = 0
		while(shuttle_spawns.len && empty_shuttle_turfs.len)
			var/turf/T = pick_n_take(empty_shuttle_turfs)
			if(T.contents.len && false_positive < 5)
				false_positive++
				continue

			var/spawn_type = pick_n_take(shuttle_spawns)
			new spawn_type(T)

//items that appear only in shuttle loan events

/obj/item/storage/belt/fannypack/yellow/bee_terrorist/PopulateContents()
	new /obj/item/grenade/c4 (src)
	new /obj/item/reagent_containers/pill/cyanide(src)
	new /obj/item/grenade/chem_grenade/facid(src)

/obj/item/paper/fluff/bee_objectives
	name = "Objectives of a Bee Liberation Front Operative"
	default_raw_text = "<b>Objective #1</b>. Liberate all bees on the NT transport vessel 2416/B. <b>Success!</b>  <br><b>Objective #2</b>. Escape alive. <b>Failed.</b>"

/obj/machinery/syndicatebomb/shuttle_loan/Initialize(mapload)
	. = ..()
	set_anchored(TRUE)
	timer_set = rand(480, 600) //once the supply shuttle docks (after 5 minutes travel time), players have between 3-5 minutes to defuse the bomb
	activate()
	update_appearance()

/obj/item/paper/fluff/cargo/bomb
	name = "hastly scribbled note"
	default_raw_text = "GOOD LUCK!"

/obj/item/paper/fluff/cargo/bomb/allyourbase
	default_raw_text = "Somebody set us up the bomb!"

#undef HIJACK_SYNDIE
#undef RUSKY_PARTY
#undef SPIDER_GIFT
#undef DEPARTMENT_RESUPPLY
#undef ANTIDOTE_NEEDED
#undef PIZZA_DELIVERY
#undef ITS_HIP_TO
#undef MY_GOD_JC
