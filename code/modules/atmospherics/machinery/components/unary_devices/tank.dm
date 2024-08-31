#define AIR_CONTENTS	((25*ONE_ATMOSPHERE)*(air_contents.return_volume())/(R_IDEAL_GAS_EQUATION*air_contents.return_temperature()))
/obj/machinery/atmospherics/components/unary/tank
	icon = 'icons/obj/atmospherics/pipes/pressure_tank.dmi'
	icon_state = "generic"

	name = "pressure tank"
	desc = "A large vessel containing pressurized gas."

	max_integrity = 800
	density = TRUE
	layer = ABOVE_WINDOW_LAYER
	pipe_flags = PIPING_ONE_PER_TURF

	var/volume = 10000 //in liters
	var/gas_type = null

/obj/machinery/atmospherics/components/unary/tank/New()
	..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.volume = volume
	air_contents.temperature = (T20C)
	if(gas_type)
		SET_MOLES(gas_type, air_contents, AIR_CONTENTS)

		name = "[name] ([GLOB.meta_gas_info[gas_type][META_GAS_NAME]])"
	set_piping_layer(piping_layer)


/obj/machinery/atmospherics/components/unary/tank/air
	icon_state = "grey"
	name = "pressure tank (Air)"

/obj/machinery/atmospherics/components/unary/tank/air/New()
	..()
	var/datum/gas_mixture/air_contents = airs[1]
	SET_MOLES(/datum/gas/oxygen, air_contents, 6*ONE_ATMOSPHERE*volume/(R_IDEAL_GAS_EQUATION*T20C) * O2STANDARD)
	SET_MOLES(/datum/gas/nitrogen, air_contents, 6*ONE_ATMOSPHERE*volume/(R_IDEAL_GAS_EQUATION*T20C) * N2STANDARD)


/obj/machinery/atmospherics/components/unary/tank/carbon_dioxide
	gas_type = /datum/gas/carbon_dioxide

/obj/machinery/atmospherics/components/unary/tank/plasma
	icon_state = "orange"
	gas_type = /datum/gas/plasma

/obj/machinery/atmospherics/components/unary/tank/oxygen
	icon_state = "blue"
	gas_type = /datum/gas/oxygen

/obj/machinery/atmospherics/components/unary/tank/nitrogen
	icon_state = "red"
	gas_type = /datum/gas/nitrogen
