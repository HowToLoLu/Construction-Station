// -------------------------
//  SmartFridge.  Much todo
// -------------------------
/obj/machinery/smartfridge
	name = "smartfridge"
	desc = "Keeps cold things cold and hot things cold."
	icon = 'icons/obj/vending.dmi'
	icon_state = "smartfridge"
	layer = BELOW_OBJ_LAYER
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 5
	active_power_usage = 100
	circuit = /obj/item/circuitboard/machine/smartfridge

	var/tgui_theme = null // default theme as null is Nanotrasen theme.

	var/max_n_of_items = 1500
	var/allow_ai_retrieve = FALSE
	var/list/initial_contents
	var/visible_contents = TRUE
	/// Is this smartfridge going to have a glowing screen? (Drying Racks are not)
	var/has_emissive = TRUE

/obj/machinery/smartfridge/Initialize(mapload)
	. = ..()
	create_reagents(100, NO_REACT)

	if(islist(initial_contents))
		for(var/typekey in initial_contents)
			var/amount = initial_contents[typekey]
			if(isnull(amount))
				amount = 1
			for(var/i in 1 to amount)
				load(new typekey(src))

/obj/machinery/smartfridge/RefreshParts()
	for(var/obj/item/stock_parts/matter_bin/B in component_parts)
		max_n_of_items = 1500 * B.rating

/obj/machinery/smartfridge/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>The status display reads: This unit can hold a maximum of <b>[max_n_of_items]</b> items.</span>"

/obj/machinery/smartfridge/update_icon_state()
	if(machine_stat)
		icon_state = "[initial(icon_state)]-off"
		return ..()

	if(!visible_contents)
		icon_state = "[initial(icon_state)]"
		return ..()

	switch(contents.len)
		if(0)
			icon_state = "[initial(icon_state)]"
		if(1 to 25)
			icon_state = "[initial(icon_state)]1"
		if(26 to 75)
			icon_state = "[initial(icon_state)]2"
		if(76 to INFINITY)
			icon_state = "[initial(icon_state)]3"
	return ..()

/obj/machinery/smartfridge/update_overlays()
	. = ..()
	if(!machine_stat && has_emissive)
		. += emissive_appearance(icon, "[initial(icon_state)]-light-mask", layer, alpha = src.alpha)
		ADD_LUM_SOURCE(src, LUM_SOURCE_MANAGED_OVERLAY)

/*******************
*   Item Adding
********************/

/obj/machinery/smartfridge/attackby(obj/item/O, mob/user, params)
	if(default_deconstruction_screwdriver(user, icon_state, icon_state, O))
		cut_overlays()
		if(panel_open)
			add_overlay("[initial(icon_state)]-panel")
		ui_update()
		return

	if(default_pry_open(O))
		return

	if(default_unfasten_wrench(user, O))
		power_change()
		return

	if(default_deconstruction_crowbar(O))
		return

	if(!machine_stat)

		if(contents.len >= max_n_of_items)
			to_chat(user, "<span class='warning'>\The [src] is full!</span>")
			return FALSE

		if(accept_check(O))
			load(O)
			user.visible_message("[user] has added \the [O] to \the [src].", "<span class='notice'>You add \the [O] to \the [src].</span>")
			if (visible_contents)
				update_appearance()
			return TRUE

		if(istype(O, /obj/item/storage/bag))
			var/obj/item/storage/P = O
			var/loaded = 0
			for(var/obj/G in P.contents)
				if(contents.len >= max_n_of_items)
					break
				if(accept_check(G))
					load(G)
					loaded++

			if(loaded)
				if(contents.len >= max_n_of_items)
					user.visible_message("[user] loads \the [src] with \the [O].", \
									 "<span class='notice'>You fill \the [src] with \the [O].</span>")
				else
					user.visible_message("[user] loads \the [src] with \the [O].", \
										 "<span class='notice'>You load \the [src] with \the [O].</span>")
				if(O.contents.len > 0)
					to_chat(user, "<span class='warning'>Some items are refused.</span>")
				if (visible_contents)
					update_appearance()
				return TRUE
			else
				to_chat(user, "<span class='warning'>There is nothing in [O] to put in [src]!</span>")
				return FALSE

		if(istype(O, /obj/item/organ_storage))
			var/obj/item/organ_storage/S = O
			if(S.contents.len)
				var/obj/item/I = S.contents[1]
				if(accept_check(I))
					load(I)
					user.visible_message("[user] inserts \the [I] into \the [src].", \
									 "<span class='notice'>You insert \the [I] into \the [src].</span>")
					O.cut_overlays()
					O.icon_state = "evidenceobj"
					O.desc = "A container for holding body parts."
					if(visible_contents)
						update_appearance()
					return TRUE
				else
					to_chat(user, "<span class='warning'>[src] does not accept [I]!</span>")
					return FALSE
			else
				to_chat(user, "<span class='warning'>There is nothing in [O] to put into [src]!</span>")
				return FALSE

	if(user.a_intent != INTENT_HARM)
		to_chat(user, "<span class='warning'>\The [src] smartly refuses [O].</span>")
		return FALSE
	else
		return ..()


/obj/machinery/smartfridge/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	if(!machine_stat)
		if (istype(AM, /obj/item))
			var/obj/item/O = AM
			if(contents.len < max_n_of_items && accept_check(O))
				load(O)
				if (visible_contents)
					update_appearance()
				return TRUE
	return ..()


/obj/machinery/smartfridge/proc/accept_check(obj/item/O)
	if(istype(O, /obj/item/food/grown/) || istype(O, /obj/item/seeds/) || istype(O, /obj/item/grown/) || istype(O, /obj/item/food/seaweed_sheet))
		return TRUE
	return FALSE

/obj/machinery/smartfridge/proc/load(obj/item/O)
	if(ismob(O.loc))
		var/mob/M = O.loc
		if(!M.transferItemToLoc(O, src))
			to_chat(usr, "<span class='warning'>\the [O] is stuck to your hand, you cannot put it in \the [src]!</span>")
			return FALSE
		else
			. = TRUE
	else
		if(SEND_SIGNAL(O.loc, COMSIG_CONTAINS_STORAGE))
			. = SEND_SIGNAL(O.loc, COMSIG_TRY_STORAGE_TAKE, O, src)
		else
			O.forceMove(src)
			. = TRUE

	if(.)
		ui_update()

///Really simple proc, just moves the object "O" into the hands of mob "M" if able, done so I could modify the proc a little for the organ fridge
/obj/machinery/smartfridge/proc/dispense(obj/item/O, var/mob/M)
	if(!M.put_in_hands(O))
		O.forceMove(drop_location())
		adjust_item_drop_location(O)



/obj/machinery/smartfridge/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/smartfridge/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SmartVend")
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/machinery/smartfridge/ui_data(mob/user)
	. = list()

	var/listofitems = list()
	for (var/I in src)
		// We do not vend our own components.
		if(I in component_parts)
			continue

		var/atom/movable/O = I
		if (!QDELETED(O))
			var/md5name = rustg_hash_string(RUSTG_HASH_MD5, O.name)
			if (listofitems[md5name])
				listofitems[md5name]["amount"]++
			else
				listofitems[md5name] = list("name" = O.name, "type" = O.type, "amount" = 1)
	sort_list(listofitems)

	.["contents"] = listofitems
	.["name"] = name
	.["isdryer"] = FALSE
	.["ui_theme"] = tgui_theme


/obj/machinery/smartfridge/handle_atom_del(atom/A) // Update the UIs in case something inside gets deleted
	SStgui.update_uis(src)

/obj/machinery/smartfridge/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("Release")
			var/desired = 0

			if(!allow_ai_retrieve && isAI(usr))
				to_chat(usr, "<span class='warning'>[src] does not seem to be configured to respect your authority!</span>")
				return

			if (params["amount"])
				desired = text2num(params["amount"])
			else
				desired = tgui_input_number(usr, "How many items would you like to take out?", "Release", max_value = 50)
				if(!desired)
					return FALSE

			if(QDELETED(src) || QDELETED(usr) || !usr.Adjacent(src)) // Sanity checkin' in case stupid stuff happens while we wait for input()
				return FALSE

			for(var/obj/item/dispensed_item in src)
				if(desired <= 0)
					break
				// Grab the first item in contents which name matches our passed name.
				// format_text() is used here to strip \improper and \proper from both names,
				// which is required for correct string comparison between them.
				if(format_text(dispensed_item.name) == format_text(params["name"]))
					if(dispensed_item in component_parts)
						CRASH("Attempted removal of [dispensed_item] component_part from smartfridge via smartfridge interface.")
					dispense(dispensed_item, usr)
					desired--

			if (visible_contents)
				update_appearance()
			return TRUE


// ----------------------------
//  Drying Rack 'smartfridge'
// ----------------------------
/obj/machinery/smartfridge/drying_rack
	name = "drying rack"
	desc = "A wooden contraption, used to dry plant products, food and leather."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "drying_rack"
	use_power = NO_POWER_USE
	visible_contents = FALSE
	has_emissive = FALSE
	var/drying = FALSE

/obj/machinery/smartfridge/drying_rack/Initialize(mapload)
	. = ..()

	// Cache the old_parts first, we'll delete it after we've changed component_parts to a new list.
	// This stops handle_atom_del being called on every part when not necessary.
	var/list/old_parts = component_parts

	component_parts = null
	circuit = null

	QDEL_LIST(old_parts)
	RefreshParts()

/obj/machinery/smartfridge/drying_rack/on_deconstruction()
	new /obj/item/stack/sheet/wood(drop_location(), 10)
	..()

/obj/machinery/smartfridge/drying_rack/RefreshParts()
/obj/machinery/smartfridge/drying_rack/default_deconstruction_screwdriver()
/obj/machinery/smartfridge/drying_rack/exchange_parts()
/obj/machinery/smartfridge/drying_rack/spawn_frame()

/obj/machinery/smartfridge/drying_rack/default_deconstruction_crowbar(obj/item/crowbar/C, ignore_panel = 1)
	..()

/obj/machinery/smartfridge/drying_rack/ui_data(mob/user)
	. = ..()
	.["isdryer"] = TRUE
	.["verb"] = "Take"
	.["drying"] = drying


/obj/machinery/smartfridge/drying_rack/ui_act(action, params)
	. = ..()
	if(.)
		update_appearance() // This is to handle a case where the last item is taken out manually instead of through drying pop-out
		return
	switch(action)
		if("Dry")
			toggle_drying(FALSE)
			return TRUE
	return FALSE

/obj/machinery/smartfridge/drying_rack/powered()
	if(!anchored)
		return FALSE
	return ..()

/obj/machinery/smartfridge/drying_rack/power_change()
	. = ..()
	if(!powered())
		toggle_drying(TRUE)

/obj/machinery/smartfridge/drying_rack/load() //For updating the filled overlay
	..()
	update_appearance()

/obj/machinery/smartfridge/drying_rack/update_icon()
	..()
	cut_overlays()
	if(drying)
		add_overlay("drying_rack_drying")
	if(contents.len)
		add_overlay("drying_rack_filled")

/obj/machinery/smartfridge/drying_rack/process()
	..()
	if(drying)
		for(var/obj/item/item_iterator in src)
			if(!accept_check(item_iterator))
				continue
			rack_dry(item_iterator)

		SStgui.update_uis(src)
		update_appearance()

/obj/machinery/smartfridge/drying_rack/accept_check(obj/item/O)
	if(HAS_TRAIT(O, TRAIT_DRYABLE)) //set on dryable element
		return TRUE
	return FALSE

/obj/machinery/smartfridge/drying_rack/proc/toggle_drying(forceoff)
	if(drying || forceoff)
		drying = FALSE
	else
		drying = TRUE
	update_appearance()

/obj/machinery/smartfridge/drying_rack/proc/rack_dry(obj/item/target)
	SEND_SIGNAL(target, COMSIG_ITEM_DRIED)

/obj/machinery/smartfridge/drying_rack/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	atmos_spawn_air("TEMP=1000")


// ----------------------------
//  Bar drink smartfridge
// ----------------------------
/obj/machinery/smartfridge/drinks
	name = "drink showcase"
	desc = "A refrigerated storage unit for tasty tasty alcohol."

/obj/machinery/smartfridge/drinks/accept_check(obj/item/O)
	if(!istype(O, /obj/item/reagent_containers) || (O.item_flags & ABSTRACT) || !O.reagents || !O.reagents.reagent_list.len)
		return FALSE
	if(istype(O, /obj/item/reagent_containers/glass) || istype(O, /obj/item/reagent_containers/food/drinks) || istype(O, /obj/item/reagent_containers/food/condiment))
		return TRUE

// ----------------------------
//  Food smartfridge
// ----------------------------
/obj/machinery/smartfridge/food
	desc = "A refrigerated storage unit for food."

/obj/machinery/smartfridge/food/accept_check(obj/item/O)
	if(IS_EDIBLE(O))
		return TRUE
	return FALSE

// -------------------------------------
// Xenobiology Slime-Extract Smartfridge
// -------------------------------------
/obj/machinery/smartfridge/extract
	name = "smart slime extract storage"
	desc = "A refrigerated storage unit for slime extracts."

/obj/machinery/smartfridge/extract/accept_check(obj/item/O)
	if(istype(O, /obj/item/slime_extract))
		return TRUE
	if(istype(O, /obj/item/slime_scanner))
		return TRUE
	return FALSE

/obj/machinery/smartfridge/extract/preloaded
	initial_contents = list(/obj/item/slime_scanner = 2)

// -------------------------
// Organ Surgery Smartfridge
// -------------------------
/obj/machinery/smartfridge/organ
	name = "smart organ storage"
	desc = "A refrigerated storage unit for organ storage."
	max_n_of_items = 20	//vastly lower to prevent processing too long
	var/repair_rate = 0

/obj/machinery/smartfridge/organ/accept_check(obj/item/O)
	if(istype(O, /obj/item/organ))
		return TRUE
	return FALSE

/obj/machinery/smartfridge/organ/load(obj/item/O)
	. = ..()
	if(!.)	//if the item loads, clear can_decompose
		return
	var/obj/item/organ/organ = O
	organ.organ_flags |= ORGAN_FROZEN

/obj/machinery/smartfridge/organ/RefreshParts()
	for(var/obj/item/stock_parts/matter_bin/B in component_parts)
		max_n_of_items = 20 * B.rating
		repair_rate = max(0, STANDARD_ORGAN_HEALING * (B.rating - 1) * 0.5)

/obj/machinery/smartfridge/organ/process(delta_time)
	for(var/organ in contents)
		var/obj/item/organ/O = organ
		if(!istype(O))
			return
		O.applyOrganDamage(-repair_rate * delta_time)

/obj/machinery/smartfridge/organ/Exited(atom/movable/gone, direction)
	. = ..()
	if(istype(gone))
		var/obj/item/organ/organ = gone
		organ.organ_flags &= ~ORGAN_FROZEN

// -----------------------------
// Chemistry Medical Smartfridge
// -----------------------------
/obj/machinery/smartfridge/chemistry
	name = "smart chemical storage"
	desc = "A refrigerated storage unit for medicine storage."

/obj/machinery/smartfridge/chemistry/accept_check(obj/item/O)
	if(istype(O, /obj/item/storage/pill_bottle))
		if(O.contents.len)
			for(var/obj/item/I in O)
				if(!accept_check(I))
					return FALSE
			return TRUE
		return FALSE
	if(!istype(O, /obj/item/reagent_containers) || (O.item_flags & ABSTRACT))
		return FALSE
	if(istype(O, /obj/item/reagent_containers/pill)) // empty pill prank ok
		return TRUE
	if(!O.reagents || !O.reagents.reagent_list.len) // other empty containers not accepted
		return FALSE
	if(istype(O, /obj/item/reagent_containers/syringe) || istype(O, /obj/item/reagent_containers/glass/bottle) || istype(O, /obj/item/reagent_containers/glass/beaker) \
	|| istype(O, /obj/item/reagent_containers/spray) || istype(O, /obj/item/reagent_containers/medspray) || istype(O, /obj/item/reagent_containers/chem_bag))
		return TRUE
	return FALSE

/obj/machinery/smartfridge/chemistry/preloaded
	initial_contents = list(
		/obj/item/reagent_containers/pill/epinephrine = 12,
		/obj/item/reagent_containers/pill/charcoal = 5,
		/obj/item/reagent_containers/glass/bottle/epinephrine = 1,
		/obj/item/reagent_containers/glass/bottle/charcoal = 1)

// ----------------------------
// Virology Medical Smartfridge
// ----------------------------
/obj/machinery/smartfridge/chemistry/virology
	name = "smart virology storage"
	desc = "A refrigerated storage unit for pathological research."

/obj/machinery/smartfridge/chemistry/virology/preloaded
	initial_contents = list(
		/obj/item/reagent_containers/syringe/antiviral = 4,
		/obj/item/reagent_containers/glass/bottle/synaptizine = 1,
		/obj/item/reagent_containers/glass/bottle/formaldehyde = 1,
		/obj/item/reagent_containers/glass/bottle/cryostylane = 1)

/obj/machinery/smartfridge/chemistry/virology/preloaded/Initialize(mapload)
	.=..()
	if(CONFIG_GET(flag/allow_virologist))
		new /obj/item/reagent_containers/glass/bottle/cold(src)
		new /obj/item/reagent_containers/glass/bottle/flu_virion(src)
		new	/obj/item/reagent_containers/glass/bottle/mutagen(src)
		new /obj/item/reagent_containers/glass/bottle/plasma(src)
	else
		desc = "A refrigerated storage unit for volatile sample storage."

/obj/machinery/smartfridge/chemistry/virology/preloaded/debug
	name = "debug virus storage"
	desc = "Oh boy, badmin at it again with the Toxoplasmosis!"

/obj/machinery/smartfridge/chemistry/virology/preloaded/debug/Initialize(mapload)
	. = ..()
	for(var/symptom in subtypesof(/datum/symptom))
		var/datum/symptom/S = new symptom
		var/datum/disease/advance/symptomholder = new
		symptomholder.name = S.name
		symptomholder.symptoms += S
		symptomholder.Finalize()
		symptomholder.Refresh()
		var/list/data = list("viruses" = list(symptomholder))
		var/obj/item/reagent_containers/glass/bottle/B = new
		B.name = "[symptomholder.name] culture bottle"
		B.desc = "A small bottle. Contains [symptomholder.agent] culture in synthblood medium."
		B.reagents.add_reagent(/datum/reagent/blood, 20, data)
		B.forceMove(src)
	for(var/disease in subtypesof(/datum/disease))
		if(!istype(disease, /datum/disease/advance))
			var/datum/disease/target = new disease
			var/list/data = list("viruses" = list(target))
			var/obj/item/reagent_containers/glass/bottle/B = new
			B.name = "[target.name] culture bottle"
			B.desc = "A small bottle. Contains [target.agent] culture in synthblood medium."
			B.reagents.add_reagent(/datum/reagent/blood, 20, data)
			B.forceMove(src)



// ----------------------------
// Disk """fridge"""
// ----------------------------
/obj/machinery/smartfridge/disks
	name = "disk compartmentalizer"
	desc = "A machine capable of storing a variety of disks. Denoted by most as the DSU (disk storage unit)."
	icon_state = "disktoaster"
	pass_flags = PASSTABLE
	visible_contents = FALSE

/obj/machinery/smartfridge/disks/accept_check(obj/item/O)
	if(istype(O, /obj/item/disk/))
		return TRUE
	else
		return FALSE

// ----------------------------
//  Sci smartfridge
// ----------------------------
/obj/machinery/smartfridge/sci
	desc = "A smart storage vender for tech."

/obj/machinery/smartfridge/sci/accept_check(obj/item/O)
	if(istype(O, /obj/item/stock_parts))
		return TRUE
	if(istype(O, /obj/item/disk/tech_disk))
		return TRUE
	if(istype(O, /obj/item/circuit_component))
		return TRUE
	if(istype(O, /obj/item/assembly))
		return TRUE
	if(istype(O, /obj/item/circuitboard))
		return TRUE
	if(istype(O, /obj/item/mecha_parts))
		return TRUE
	return FALSE
