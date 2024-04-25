#define PDA_CHARGE_RATE_MULTIPLIER 0.2

/obj/machinery/cell_charger
	name = "cell charger"
	desc = "It charges power cells."
	icon = 'icons/obj/power.dmi'
	icon_state = "ccharger"
	use_power = IDLE_POWER_USE
	idle_power_usage = 5
	active_power_usage = 60
	power_channel = AREA_USAGE_EQUIP
	circuit = /obj/item/circuitboard/machine/cell_charger
	pass_flags = PASSTABLE
	var/obj/item/stock_parts/cell/charging = null
	var/obj/item/modular_computer/tablet/pda/pda = null
	var/chargelevel = -1
	var/charge_rate = 250

/obj/machinery/cell_charger/update_overlays()
	. = ..()
	if(charging)
		. += pda ? "pda" : "ccharger-on"
		if(!(machine_stat & (BROKEN|NOPOWER)))
			var/newlevel = 	round(charging.percent() * 4 / 100)
			chargelevel = newlevel
			. += "ccharger-o[newlevel]"

/obj/machinery/cell_charger/examine(mob/user)
	. = ..()
	. += "There's [charging ? "a" : "no"] [pda ? "pda" : "cell"] in the charger."
	if(charging)
		. += "Current charge: [round(charging.percent(), 1)]%."
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>The status display reads: Charging power: <b>[charge_rate]W</b>.</span>"

/obj/machinery/cell_charger/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour)
		if(!charging && ( \
			default_deconstruction_screwdriver(user, icon_state, icon_state, W) || \
			default_unfasten_wrench(user, W))
		)
			return
		else if(default_deconstruction_crowbar(W))
			return

	var/obj/item/stock_parts/W_cell = W
	var/obj/item/modular_computer/tablet/pda/W_pda = W
	if(!panel_open && (istype(W_cell) || istype(W_pda)))
		if(machine_stat & BROKEN)
			to_chat(user, "<span class='warning'>[src] is broken!</span>")
			return
		if(!anchored)
			to_chat(user, "<span class='warning'>[src] isn't attached to the ground!</span>")
			return
		if(charging || pda) //just in case somehow there's a PDA here without a cell
			to_chat(user, "<span class='warning'>The charger is already in use!</span>")
			return

		var/area/a = get_area(src) // Gets our locations location, like a dream within a dream
		if(!isarea(a))
			return
		if(a.power_equip == 0) // There's no APC in this area, don't try to cheat power!
			to_chat(user, "<span class='warning'>[src] blinks red as you try to insert [W]!</span>")
			return

		if(istype(W_pda))
			var/pda_cell = W_pda.get_cell()
			if(!pda_cell)
				to_chat(user, "<span class='warning'>There is no power cell in [W]!</span>")
				return
			if(!user.transferItemToLoc(W,src))
				return

			pda = W
			charging = pda_cell
			RegisterSignal(charging, COMSIG_PARENT_QDELETING, PROC_REF(pda_cell_destroyed))
			user.visible_message("<span class='notice'>[user] inserts a PDA into [src].</span>", \
				"<span class='notice'>You insert [W] into [src].</span>")
			chargelevel = -1
			update_icon()
			return
		else //presumed istype(W_cell) to be true at this point
			if(!user.transferItemToLoc(W,src))
				return

			charging = W
			user.visible_message("<span class='notice'>[user] inserts a cell into [src].<span class='notice'>", \
				"<span class='notice'>You insert [W] into [src].</span>")
			chargelevel = -1
			update_icon()
			return
	else
		return ..()

/// COMSIG_PARENT_QDELETING Exited doesn't recieve nested exits, so we have to handle sudden PDA cell deletion here.
/obj/machinery/cell_charger/proc/pda_cell_destroyed(datum/source)
	SIGNAL_HANDLER

	charging = null
	if(pda)
		visible_message("<span class='warning'>[pda] pops out of [src]!</span>")
		pda.forceMove(drop_location())


/obj/machinery/cell_charger/Exited(atom/movable/leaving, direction) //Handles the PDA or cell leaving our immediate contents
	. = ..()
	if(leaving == pda || leaving == charging)
		if(pda && charging)
			UnregisterSignal(charging, COMSIG_PARENT_QDELETING)
		pda = null
		charging?.update_icon()
		charging = null
		chargelevel = -1
		update_icon()

/obj/machinery/cell_charger/deconstruct()
	if(pda)
		pda.forceMove(drop_location())
	else if(charging)
		charging.forceMove(drop_location())
	return ..()

/obj/machinery/cell_charger/attack_hand(mob/user)
	. = ..()

	var/obj/to_pop_out = pda || charging
	if(. || !to_pop_out)
		return

	user.visible_message("<span class='notice'>[user] removes a [pda ? "PDA" : "cell"] from [src].<span class='notice'>", \
		"<span class='notice'>You remove [to_pop_out] from [src].</span>")
	to_pop_out.add_fingerprint(user)
	user.put_in_hands(to_pop_out)

/obj/machinery/cell_charger/attack_tk(mob/user)
	var/obj/to_pop_out = pda || charging
	if(!to_pop_out)
		return

	visible_message("<span class='warning'>[to_pop_out] pops out of [src]!</span>", ignored_mobs = user)
	to_chat(user, "<span class='notice'>You telekinetically remove [to_pop_out] from [src].</span>")
	to_pop_out.forceMove(loc)

/obj/machinery/cell_charger/attack_ai(mob/user)
	return

/obj/machinery/cell_charger/emp_act(severity)
	. = ..()

	if(machine_stat & (BROKEN|NOPOWER) || . & EMP_PROTECT_CONTENTS)
		return

	if(pda)
		pda.emp_act(severity)
	else if(charging)
		charging.emp_act(severity)

/obj/machinery/cell_charger/RefreshParts()
	charge_rate = 250
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		charge_rate *= C.rating

/obj/machinery/cell_charger/process(delta_time)
	if(!charging || !anchored || (machine_stat & (BROKEN|NOPOWER)))
		return

	if(charging.percent() >= 100)
		return
	use_power(charge_rate * delta_time * (pda? PDA_CHARGE_RATE_MULTIPLIER : 1))
	charging.give(charge_rate * delta_time * (pda? PDA_CHARGE_RATE_MULTIPLIER : 1))	//this is 2558, efficient batteries exist

	update_icon()
