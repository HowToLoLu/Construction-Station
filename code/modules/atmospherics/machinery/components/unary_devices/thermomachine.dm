#define THERMOMACHINE_POWER_CONVERSION 0.01

/obj/machinery/atmospherics/components/unary/thermomachine
	icon = 'icons/obj/atmospherics/components/thermomachine.dmi'
	icon_state = "thermo_base"

	name = "Thermomachine"
	desc = "Heats or cools gas in connected pipes."

	density = TRUE
	max_integrity = 300
	armor = list(MELEE = 0,  BULLET = 0, LASER = 0, ENERGY = 100, BOMB = 0, BIO = 100, RAD = 100, FIRE = 80, ACID = 30, STAMINA = 0, BLEED = 0)
	layer = OBJ_LAYER
	circuit = /obj/item/circuitboard/machine/thermomachine

	move_resist = MOVE_RESIST_DEFAULT
	vent_movement = NONE
	pipe_flags = PIPING_ONE_PER_TURF

	greyscale_config = /datum/greyscale_config/thermomachine
	greyscale_colors = COLOR_VIBRANT_LIME

	set_dir_on_move = FALSE

	var/min_temperature = T20C //actual temperature will be defined by RefreshParts()
	var/max_temperature = T20C //actual temperature will be defined by RefreshParts()
	var/target_temperature = T20C
	var/heat_capacity = 0
	var/interactive = TRUE // So mapmakers can disable interaction.
	var/base_heating = 140
	var/base_cooling = 170

/obj/machinery/atmospherics/components/unary/thermomachine/Initialize(mapload)
	. = ..()
	RefreshParts()
	update_appearance()

/obj/machinery/atmospherics/components/unary/thermomachine/is_connectable()
	if(!anchored)
		return FALSE
	. = ..()

/obj/machinery/atmospherics/components/unary/thermomachine/on_construction(mob/user, obj_color, set_layer)
	var/obj/item/circuitboard/machine/thermomachine/board = circuit
	if(board)
		piping_layer = board.pipe_layer
		set_layer = piping_layer

	..() //Skipping the rest of on_construction() would be a bad idea so we clean up after it instead.

	if(check_pipe_on_turf())
		set_anchored(FALSE)
		panel_open = TRUE
		icon_state = "thermo-open"
		balloon_alert(user, "the port is already in use!")

/obj/machinery/atmospherics/components/unary/thermomachine/RefreshParts()
	var/calculated_bin_rating
	for(var/obj/item/stock_parts/matter_bin/bin in component_parts)
		calculated_bin_rating += bin.rating
	heat_capacity = 5000 * ((calculated_bin_rating - 1) ** 2)

	var/calculated_laser_rating = 0
	for(var/obj/item/stock_parts/micro_laser/laser in component_parts)
		calculated_laser_rating += laser.rating
	min_temperature = max(T0C - (base_cooling + calculated_laser_rating * 15), TCMB) //73.15K with T1 stock parts
	max_temperature = T20C + (base_heating * calculated_laser_rating) //573.15K with T1 stock parts

/obj/machinery/atmospherics/components/unary/thermomachine/update_icon()
	var/colors_to_use = ""
	switch(target_temperature)
		if(BODYTEMP_HEAT_WARNING_3 to INFINITY)
			colors_to_use = COLOR_RED
		if(BODYTEMP_HEAT_WARNING_2 to BODYTEMP_HEAT_WARNING_3)
			colors_to_use = COLOR_ORANGE
		if(BODYTEMP_HEAT_WARNING_1 to BODYTEMP_HEAT_WARNING_2)
			colors_to_use = COLOR_YELLOW
		if(BODYTEMP_COLD_WARNING_1 to BODYTEMP_HEAT_WARNING_1)
			colors_to_use = COLOR_VIBRANT_LIME
		if(BODYTEMP_COLD_WARNING_2 to BODYTEMP_COLD_WARNING_1)
			colors_to_use = COLOR_CYAN
		if(BODYTEMP_COLD_WARNING_3 to BODYTEMP_COLD_WARNING_2)
			colors_to_use = COLOR_BLUE
		else
			colors_to_use = COLOR_VIOLET

	if(greyscale_colors != colors_to_use)
		set_greyscale(colors=colors_to_use)

	if(panel_open)
		icon_state = "thermo-open"
		return ..()
	if(on && is_operational)
		icon_state = "thermo_1"
		return ..()
	icon_state = "thermo_base"
	return ..()

/obj/machinery/atmospherics/components/unary/thermomachine/update_overlays()
	. = ..()
	if(!initial(icon))
		return
	var/mutable_appearance/thermo_overlay = new(initial(icon))
	. += get_pipe_image(thermo_overlay, "pipe", dir, pipe_color, piping_layer)

/obj/machinery/atmospherics/components/unary/thermomachine/examine(mob/user)
	. = ..()
	. += "<span class='notice'>The thermostat is set to [target_temperature]K ([(T0C-target_temperature)*-1]C).</span>"
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>The status display reads: Efficiency <b>[(heat_capacity/7500)*100]%</b>.</span>"
		. += "<span class='notice'>Temperature range <b>[min_temperature]K - [max_temperature]K ([(T0C-min_temperature)*-1]C - [(T0C-max_temperature)*-1]C)</b>.</span>"

/obj/machinery/atmospherics/components/unary/thermomachine/AltClick(mob/living/user)
	if(panel_open)
		balloon_alert(user, "close panel!")
		return TRUE

	if(target_temperature == T20C)
		target_temperature = max_temperature
	else if(target_temperature == max_temperature)
		target_temperature = min_temperature
	else
		target_temperature = T20C

	investigate_log("was set to [target_temperature] K by [key_name(user)]", INVESTIGATE_ATMOS)
	balloon_alert(user, "temperature reset to [target_temperature] K")
	update_appearance()

/// Performs heat calculation for the freezer.
/// We just equalize the gasmix with an object at temp = var/target_temperature and heat cap = var/heat_capacity
/obj/machinery/atmospherics/components/unary/thermomachine/process_atmos()
	if(!on)
		return

	var/turf/local_turf = get_turf(src)

	if(!is_operational || !local_turf)
		on = FALSE
		update_appearance()
		return

	// The gas we want to cool/heat
	var/datum/gas_mixture/port = airs[1]

	if(!port.total_moles()) // Nothing to cool? go home lad
		return

	var/port_capacity = port.heat_capacity()

	// The difference between target and what we need to heat/cool. Positive if heating, negative if cooling.
	var/temperature_target_delta = target_temperature - port.temperature

	// We perfectly can do W1+W2 / C1+C2 here but this lets us count the power easily.
	var/heat_amount = CALCULATE_CONDUCTION_ENERGY(temperature_target_delta, port_capacity, heat_capacity)

	port.temperature = max(((port.temperature * port_capacity) + heat_amount) / port_capacity, TCMB)

	heat_amount = min(abs(heat_amount), 1e8) * THERMOMACHINE_POWER_CONVERSION

	// This produces a nice curve that scales decently well for really hot stuff, and is nice to not fusion. It'll do
	var/power_usage = idle_power_usage + (heat_amount * 0.05) ** (1.05 - (5e7 * 0.16 / max(heat_amount, 5e7)))

	active_power_usage = power_usage
	update_parents()


/obj/machinery/atmospherics/components/unary/thermomachine/attackby(obj/item/tool, mob/user, params)
	if(!on)
		if(default_deconstruction_screwdriver(user, "thermo-open", "thermo-0", tool))
			return
	if(default_change_direction_wrench(user, tool))
		return
	if(default_deconstruction_crowbar(tool))
		return
	return ..()

/obj/machinery/atmospherics/components/unary/thermomachine/multitool_act(mob/living/user, obj/item/multitool/multitool)
	if(!panel_open)
		balloon_alert(user, "open panel!")
		return TRUE
	piping_layer = (piping_layer >= PIPING_LAYER_MAX) ? PIPING_LAYER_MIN : (piping_layer + 1)
	to_chat(user, "<span class='notice'>You change the circuitboard to layer [piping_layer].</span>")
	if(anchored)
		reconnect_nodes()
	update_appearance()
	return TRUE

/obj/machinery/atmospherics/components/unary/thermomachine/proc/check_pipe_on_turf()
	for(var/obj/machinery/atmospherics/device in get_turf(src))
		if(device == src)
			continue
		if(device.piping_layer == piping_layer)
			return TRUE
	return FALSE

/obj/machinery/atmospherics/components/unary/thermomachine/ui_status(mob/user)
	if(interactive)
		return ..()
	return UI_CLOSE

/obj/machinery/atmospherics/components/unary/thermomachine/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/atmospherics/components/unary/thermomachine/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ThermoMachine")
		ui.open()
		ui.set_autoupdate(TRUE) // Air temperature and pressure

/obj/machinery/atmospherics/components/unary/thermomachine/ui_data(mob/user)
	var/list/data = list()
	data["on"] = on

	data["min"] = min_temperature
	data["max"] = max_temperature
	data["target"] = target_temperature
	data["initial"] = initial(target_temperature)

	var/datum/gas_mixture/air1 = airs[1]
	data["temperature"] = air1.return_temperature()
	data["pressure"] = air1.return_pressure()
	return data

/obj/machinery/atmospherics/components/unary/thermomachine/ui_act(action, params)

	if(..())
		return

	switch(action)
		if("power")
			on = !on
			use_power = on ? ACTIVE_POWER_USE : IDLE_POWER_USE
			investigate_log("was turned [on ? "on" : "off"] by [key_name(usr)]", INVESTIGATE_ATMOS)
			. = TRUE
		if("target")
			var/target = params["target"]
			var/adjust = text2num(params["adjust"])
			if(target == "input")
				target = input("Set new target ([min_temperature]-[max_temperature] K):", name, target_temperature) as num|null
				if(!isnull(target))
					. = TRUE
			else if(adjust)
				target = target_temperature + adjust
				. = TRUE
			else if(text2num(target) != null)
				target = text2num(target)
				. = TRUE
			if(.)
				target_temperature = clamp(target, min_temperature, max_temperature)
				investigate_log("was set to [target_temperature] K by [key_name(usr)]", INVESTIGATE_ATMOS)
	update_icon()

/obj/machinery/atmospherics/components/unary/thermomachine/CtrlClick(mob/living/user)
	if(!anchored)
		return TRUE
	if(panel_open)
		balloon_alert(user, "close panel!")
		return TRUE
	if(!is_operational)
		return TRUE

	on = !on
	balloon_alert(user, "turned [on ? "on" : "off"]")
	investigate_log("was turned [on ? "on" : "off"] by [key_name(user)]", INVESTIGATE_ATMOS)
	update_icon()
	return TRUE

/obj/machinery/atmospherics/components/unary/thermomachine/update_layer()
	return

/obj/machinery/atmospherics/components/unary/thermomachine/freezer

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/layer1
	piping_layer = 1

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/layer2
	piping_layer = 2

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/layer4
	piping_layer = 4

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/layer5
	piping_layer = 5

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/on
	on = TRUE
	icon_state = "thermo_base_1"

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/on/Initialize(mapload)
	. = ..()
	if(target_temperature == initial(target_temperature))
		target_temperature = min_temperature
/obj/machinery/atmospherics/components/unary/thermomachine/freezer/on/coldroom
	name = "Cold room temperature control unit"
	icon_state = "thermo_base_1"
	greyscale_colors = COLOR_CYAN

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/on/coldroom/Initialize(mapload)
	. = ..()
	target_temperature = COLD_ROOM_TEMP

/obj/machinery/atmospherics/components/unary/thermomachine/heater

/obj/machinery/atmospherics/components/unary/thermomachine/heater/layer1
	piping_layer = 1

/obj/machinery/atmospherics/components/unary/thermomachine/heater/layer2
	piping_layer = 2

/obj/machinery/atmospherics/components/unary/thermomachine/heater/layer4
	piping_layer = 4

/obj/machinery/atmospherics/components/unary/thermomachine/heater/layer5
	piping_layer = 5

/obj/machinery/atmospherics/components/unary/thermomachine/heater/on
	on = TRUE
	icon_state = "thermo_base_1"

#define QUICK_LAYER_HELPER(PATH)\
##PATH/layer_1 {\
	piping_layer = 1;\
}\
##PATH/layer_2 {\
	piping_layer = 2;\
}\
##PATH/layer_4 {\
	piping_layer = 4;\
}\
##PATH/layer_5 {\
	piping_layer = 5;\
}

QUICK_LAYER_HELPER(/obj/machinery/atmospherics/components/unary/thermomachine/heater)
QUICK_LAYER_HELPER(/obj/machinery/atmospherics/components/unary/thermomachine/heater/on)
QUICK_LAYER_HELPER(/obj/machinery/atmospherics/components/unary/thermomachine/on)
QUICK_LAYER_HELPER(/obj/machinery/atmospherics/components/unary/thermomachine/freezer)
QUICK_LAYER_HELPER(/obj/machinery/atmospherics/components/unary/thermomachine/freezer/on)
QUICK_LAYER_HELPER(/obj/machinery/atmospherics/components/unary/thermomachine/freezer/on/coldroom)

#undef QUICK_LAYER_HELPER
#undef THERMOMACHINE_POWER_CONVERSION
