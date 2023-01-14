/datum/faction_request
	///A short title to show as header
	var/title = "very important mission!!!!!"
	///Whether the request has been accepted
	var/accepted = FALSE
	///Comms message that is being shown to the comms console
	var/datum/comm_message/comms_message
	///Reference to the requesting faction
	var/datum/faction/requesting_faction
	///Reputation penalty for failing/denying. takes negative numbers only. BE SURE TO MENTION THIS IN THE EXPLANATION!!!
	var/failure_penalty = 0
	///Time you have to accept the initial request
	var/accept_time = 10 MINUTES
	///Time you have to finish the request
	var/completion_time = 20 MINUTES
	///Has this request been completed?
	var/completed = FALSE

/datum/faction_request/New(requesting_faction)
	. = ..()
	src.requesting_faction = requesting_faction
	on_request_created()
	setup_initial_message()

///Returns an explanation of the request
/datum/faction_request/proc/get_explanation()
	return "very important explanation from us, [requesting_faction.name], that you must complete or you will LITERALY die!!!"

///Returns a message that will get sent if the request is failed somehow. Only sent if you actively fuck up. (e.g. letting it time out)
/datum/faction_request/proc/get_failure_message()
	return "you screwed us, [requesting_faction.name], you evil rat!"

///Proc that can be overriden to determine if a request can be handed in.
/datum/faction_request/proc/can_be_handed_in()
	return FALSE

///Proc that gets ran if a request is failed/denied. Removes reputation if requested
/datum/faction_request/proc/on_failure(silent)
	requesting_faction.add_relationship(failure_penalty)
	priority_announce(get_failure_message(), title, SSstation.announcer.get_rand_report_sound())
	on_ended()

///Proc that gets ran if a request is completed.
/datum/faction_request/proc/on_completion()
	on_ended()

///Proc that gets ran if a request is ended (failure or completion)
/datum/faction_request/proc/on_ended()
	qdel(src)

///Handles any generation required on request creation
/datum/faction_request/proc/on_request_created()
	return

///Sends the initial comms message, this will allow users to accept/deny the request.
/datum/faction_request/proc/setup_initial_message()
	comms_message = new(title, get_explanation(), list("Accept","Reject"), list("Accept" = CALLBACK(src, PROC_REF(can_be_accepted))))
	comms_message.answer_callback = CALLBACK(src, PROC_REF(request_answered))
	comms_message.deletion_callback = CALLBACK(src, PROC_REF(request_deleted))
	priority_announce(get_explanation(), "New request from [requesting_faction.name]: [title]", SSstation.announcer.get_rand_report_sound())
	SScommunications.send_message(comms_message, unique = TRUE)

///Returns whether or not the request can be accepted.
/datum/faction_request/proc/can_be_accepted()
	return TRUE

///Gets called when the initial request is accepted or denied.
/datum/faction_request/proc/request_answered()
	if(comms_message.answered == COMMS_REQUEST_DENIED)
		on_failure(silent = TRUE)
		return

	accepted = TRUE
	comms_message.refresh_message(title, get_explanation(), list("Complete"), list("Complete" = CALLBACK(src, PROC_REF(can_be_handed_in))))
	comms_message.answer_callback = CALLBACK(src, PROC_REF(request_handed_in))

///Called when the request is officially accepted. Override to start any events if necesary
/datum/faction_request/proc/request_accepted()
	return

///Called by comms_message when handed in
/datum/faction_request/proc/request_handed_in()
	if(!can_be_handed_in()) //In case we somehow answered complete but it isnt even done yet.
		return
	comms_message.remove_answers()

///Called by the comms message if the message gets deleted, which is basically a manual cancellation.
/datum/faction_request/proc/request_deleted()
	if(completed)
		return

	on_failure(silent = !accepted)
