/datum/computer_file/program/gallery
	filename = "gallery"
	filedesc = "Gallery"
	category = PROGRAM_CATEGORY_MISC
	extended_desc = "Enables you to view stored pictures on a device"
	size = 1
	program_icon_state = "gallery"

	usage_flags = PROGRAM_ALL
	tgui_id = "NtosGallery"
	program_icon = "images"

/datum/computer_file/program/gallery/ui_assets(mob/user)
	. = ..()
