/obj/vehicle/ridden/rock
	name = "large rock"
	icon_state = "basalt3"
	desc = "A volcanic rock. Pioneers used to ride these babies for miles. This one seems like it still could!"
	icon = 'icons/obj/flora/rocks.dmi'
	density = TRUE
	resistance_flags = FIRE_PROOF

/obj/vehicle/ridden/rock/Initialize(mapload)
	. = ..()
	update_appearance()
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/rock)
