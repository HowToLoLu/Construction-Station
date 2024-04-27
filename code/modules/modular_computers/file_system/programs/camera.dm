/datum/computer_file/program/camera
	filename = "camera"
	filedesc = "Camera"
	category = PROGRAM_CATEGORY_MISC
	extended_desc = "Allows you to take pictures of things (Additional hardware required)"
	size = 2
	program_icon_state = "camera"
	usage_flags = PROGRAM_TABLET
	tgui_id = "NtosCamera"
	program_icon = "camera"

	use_attack = TRUE
	use_attack_obj = TRUE

	var/capture_width = 2
	var/capture_height = 2
	// Used to take pictures
	var/obj/item/camera/pda/item_camera
	// Holds onto a picture for the user to preview before saving
	var/datum/picture/captured
	// An error message in case of failing to save the file
	var/error

/datum/computer_file/program/camera/on_start(mob/living/user)
	. = ..()
	if(.)
		item_camera = new(holder.get_modular_computer_part(MC_CAMERA))

/datum/computer_file/program/camera/kill_program(forced)
	. = ..()
	QDEL_NULL(item_camera)

/datum/computer_file/program/camera/on_ui_create(mob/user, datum/tgui/ui)
	. = ..()
	stack_trace("on_ui_create!!") //Debug message to learn how this interacts with minimizing programs
	if(!item_camera)
		item_camera = new(holder.get_modular_computer_part(MC_CAMERA))

/datum/computer_file/program/camera/on_ui_close(mob/user, datum/tgui/tgui)
	. = ..()
	QDEL_NULL(item_camera)

/datum/computer_file/program/camera/can_run(mob/user, loud, access_to_check, transfer, list/access)
	if(!transfer && !holder.get_modular_computer_part(MC_CAMERA))
		if(loud)
			to_chat(user, "<span class='warning'>An error flashes onscreen, \"NO CAMERA MODULE FOUND\"</span>")
		return FALSE
	return ..()

/datum/computer_file/program/camera/attack(atom/target, mob/living/user, params)
	. = ..()
	if(item_camera.hardware_camera.holder == holder.holder)
		INVOKE_ASYNC(item_camera, TYPE_PROC_REF(/obj/item/camera/pda, captureimage), target, user, capture_width, capture_height)
		return TRUE
	else
		stack_trace("Invalid item camera \ref[item_camera] owned by camera program!")
		item_camera = null
		return FALSE

/datum/computer_file/program/camera/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	switch(action)
		if("setWidth")
			capture_width = round(clamp(params["newWidth"], 1, 4))
			return TRUE
		if("setHeight")
			capture_width = round(clamp(params["newHeight"], 1, 4))
			return TRUE
		if("savePicture")
			var/datum/computer_file/data/picture/temp_file = new()
			temp_file.set_stored_data(captured)
			if(holder.can_store_file(temp_file)) //Usually shouldn't be able to click this button
				temp_file.filename = "[station_time_timestamp("hh-mm-ss")]_[time2text(world.realtime, "DD-MM")]-[GLOB.year_integer+YEAR_OFFSET]"
				holder.store_file(temp_file)
				captured = null
			else
				error = "Could not save picture! Please minimize the app and manage your files, then try again."
			return TRUE
		if("discardPicture")
			captured = null
			return TRUE
		if("dismissError")
			error = null
			return TRUE

/datum/computer_file/program/camera/ui_static_data(mob/user)
	var/list/data = list()

	var/list/min_max_data = list()
	min_max_data["min_width"] = 1
	min_max_data["min_height"] = 1
	min_max_data["max_width"] = 4
	min_max_data["max_height"] = 4

	data["min_max_data"] = min_max_data

	return data

/datum/computer_file/program/camera/ui_data(mob/user)
	var/list/data = list()
	if(captured)
		var/list/picture_data = list()
		user << browse_rsc(captured.picture_image, captured.id)
		picture_data["picture_id"] = captured.id
		picture_data["picture_width"] = captured.psize_x
		picture_data["picture_height"] = captured.psize_y

		data["picture"] = picture_data
		data["error"] = error
	else
		var/list/control_data = list()
		control_data["cur_width"] = capture_width
		control_data["cur_height"] = capture_height

		data["control_data"] = control_data
		data["space"] = holder.max_capacity - holder.used_capacity

	return data

/datum/computer_file/program/camera/ui_assets(mob/user)
	. = ..()
