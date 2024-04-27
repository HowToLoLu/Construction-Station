/obj/item/camera/pda
	name = "small internal camera"
	desc = "you feel like you shouldn't be seeing this"
	pictures_left = INFINITY
	pictures_max = INFINITY
	var/obj/item/computer_hardware/camera_component/hardware_camera

/obj/item/camera/pda/Initialize(mapload)
	hardware_camera = loc
	if(!istype(hardware_camera))
		return INITIALIZE_HINT_QDEL
	. = ..()

/obj/item/camera/pda/burn()
	return

/obj/item/camera/pda/after_picture(mob/user, datum/picture/picture, proximity_flag)
	var/obj/item/modular_computer/comp = hardware_camera.holder

	if(istype(comp.active_program, /datum/computer_file/program/camera))
		var/datum/computer_file/program/camera/cam_prog = comp.active_program
		cam_prog.captured = picture
		return
	else
		CRASH("A PDA camera item took a picture, but there was no active program capable of handling it!")
