class_name ComicSavesMenu
extends Window

const DIR_SAVES:String = "user://saves/"
var panels:GridContainer
var save_mode:bool
var blank_texture:ImageTexture = ImageTexture.create_from_image(Image.create(ProjectSettings.get_setting("display/window/size/viewport_width") / 4, ProjectSettings.get_setting("display/window/size/viewport_height") / 4, false, Image.FORMAT_RGB8))


func _init(_save_mode:bool):
	if not DirAccess.dir_exists_absolute(DIR_SAVES):
		DirAccess.make_dir_absolute(DIR_SAVES)
	save_mode = _save_mode
	title = "Save" if save_mode else "Load"
	exclusive = true
	close_requested.connect(queue_free)

	panels = GridContainer.new()
	add_child(panels)
	panels.columns = 3
	panels.resized.connect(_on_panels_resized)

	for i in range(1,10):
		var save_exists:bool = FileAccess.file_exists(str(DIR_SAVES, "data_", i, ".sav"))
		var panel:VBoxContainer = VBoxContainer.new()
		panels.add_child(panel)
		var button = TextureButton.new()
		panel.add_child(button)
		if save_exists and FileAccess.file_exists(str(DIR_SAVES, "thumb_", i, ".webp")):
			var image:Image = Image.new()
			var err = image.load(str(DIR_SAVES, "thumb_", i, ".webp"))
			if err == OK:
				button.texture_normal = ImageTexture.create_from_image(image)
			else:
				button.texture_normal = blank_texture
		else:
			button.texture_normal = blank_texture
		if save_mode or save_exists:
			button.pressed.connect(_on_button_pressed.bind(i))
		var label:Label = Label.new()
		panel.add_child(label)
		label.text = str(i, ": Empty Slot")

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
		var file = FileAccess.open(str(DIR_SAVES, "data_", save_id, ".sav"), FileAccess.WRITE)
		file.store_var(Comic.vars)
		# We call deferred so that the menu won't appear in the thumbnail
		var capture = Comic.book.page.get_texture().get_image()
		capture.resize(blank_texture.get_width(), blank_texture.get_height())
		capture.save_webp(str(DIR_SAVES, "thumb_", save_id, ".webp"))
	else:
		print("TEST")
		var file = FileAccess.open(str(DIR_SAVES, "data_", save_id, ".sav"), FileAccess.READ)
		Comic.vars = file.get_var()
		Comic.book.change_page = true
	queue_free()


