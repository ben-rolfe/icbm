class_name ComicSavesMenu
extends Window

const MONTH_NAMES = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
var panels:GridContainer
var save_mode:bool
var blank_texture:ImageTexture = ImageTexture.create_from_image(Image.create(ProjectSettings.get_setting("display/window/size/viewport_width") / 4, ProjectSettings.get_setting("display/window/size/viewport_height") / 4, false, Image.FORMAT_RGB8))

func _init(_save_mode:bool):
	if not DirAccess.dir_exists_absolute(Comic.DIR_SAVES):
		DirAccess.make_dir_absolute(Comic.DIR_SAVES)
	save_mode = _save_mode
	title = "Save" if save_mode else "Load"
	exclusive = true
	close_requested.connect(queue_free)

	panels = GridContainer.new()
	add_child(panels)
	panels.columns = 3
	panels.resized.connect(_on_panels_resized)

	for i in 9:
		var save_exists:bool = FileAccess.file_exists(str(Comic.DIR_SAVES, "data_", i, ".sav"))
		var panel:VBoxContainer = VBoxContainer.new()
		panels.add_child(panel)
		var button = TextureButton.new()
		panel.add_child(button)
		if save_exists and FileAccess.file_exists(str(Comic.DIR_SAVES, "thumb_", i, ".webp")):
			var image:Image = Image.new()
			var err = image.load(str(Comic.DIR_SAVES, "thumb_", i, ".webp"))
			if err == OK:
				button.texture_normal = ImageTexture.create_from_image(image)
			else:
				button.texture_normal = blank_texture
		else:
			button.texture_normal = blank_texture
		if (save_mode and (i > 0 or not Comic.book.auto_save_slot)) or (not save_mode and save_exists):
			button.pressed.connect(_on_button_pressed.bind(i))
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		else:
			button.disabled = true
			button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		var label:Label = Label.new()
		panel.add_child(label)
		if save_exists:
			var dict:Dictionary = Time.get_datetime_dict_from_unix_time(FileAccess.get_modified_time(str(Comic.DIR_SAVES, "data_", i, ".sav")) + Time.get_time_zone_from_system().bias * 60)
			label.text = str(dict.day, " ", MONTH_NAMES[dict.month - 1], " ", dict.year, ", ", dict.hour, ":", dict.minute)
		else:
			label.text = str("Empty Slot")
		if i==0 and Comic.book.auto_save_slot:
			label.text = str("AUTO-SAVE (", label.text, ")")

static func open(_save_mode:bool = false):
	var menu:ComicSavesMenu = ComicSavesMenu.new(_save_mode)
	Comic.add_child(menu)
	menu.popup_centered()

func _on_panels_resized():
	size = Vector2(min(panels.size.x, Comic.size.x - 80), min(panels.size.y, Comic.size.y - 80))
	move_to_center()

func _on_button_pressed(save_id:int):
	hide()
	if save_mode:
		Comic.save_savefile(save_id)
	else:
		Comic.load_savefile(save_id)
	queue_free()


