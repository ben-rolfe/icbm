class_name ComicEditorImageExplorer
extends AcceptDialog

static var singleton:ComicEditorImageExplorer
var file_list:VBoxContainer
var address_text:LineEdit
var path:String
var callable:Callable

static func open(callable:Callable):
	if singleton == null:
		singleton = ComicEditorImageExplorer.new()
		var parent:ComicEditor = Comic.book
		parent.add_child(singleton)
		singleton.title = "Select an Image"
		singleton.ok_button_text = "Cancel"
		singleton.size = Vector2i(480, parent.get_viewport().size.y * 0.8)
		singleton.position = Vector2i((parent.get_viewport().size.x - singleton.size.x) * 0.5, parent.get_viewport().size.y * 0.1)

		var v_box = VBoxContainer.new()
		singleton.add_child(v_box)
		v_box.size = singleton.size


		var address_bar = HBoxContainer.new()
		v_box.add_child(address_bar)

		var up_button = Button.new()
		address_bar.add_child(up_button)
		up_button.icon = load(str(ComicEditor.DIR_ICONS, str("folder_up.svg")))
#		up_button.focus_mode = Control.FOCUS_NONE
		up_button.pressed.connect(singleton._on_up_pressed)
		
		singleton.address_text = LineEdit.new()
		address_bar.add_child(singleton.address_text)
		singleton.address_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		singleton.address_text.caret_blink = true
		singleton.address_text.text_submitted.connect(singleton._on_address_submitted)

		var favorite_button = Button.new()
		address_bar.add_child(favorite_button)
		favorite_button.icon = load(str(ComicEditor.DIR_ICONS, str("favorite.svg")))
#		favorite_button.focus_mode = Control.FOCUS_NONE
		favorite_button.pressed.connect(singleton._on_favorite_pressed)


		var scroll_container = ScrollContainer.new()
		v_box.add_child(scroll_container)
		scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

		singleton.file_list = VBoxContainer.new()
		singleton.file_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		singleton.file_list.add_theme_constant_override("separation", 0)
		scroll_container.add_child(singleton.file_list)

	singleton.callable = callable
	singleton.path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	#TODO: Open faved folder.
	singleton.show()
	singleton.open_dir(ComicEditor.load_setting("favorite_image_path", ""))

func open_dir(new_path:String):
	if new_path.length() == 0:
		new_path = path
	# Remove multiple slashes
	new_path = "/".join(new_path.split("/", false))
	if new_path.right(1) != "/":
		new_path = str(new_path, "/")
	var dir:DirAccess = DirAccess.open(new_path)
	if dir == null:
		dir = DirAccess.open(path)
	else:
		path = new_path
	address_text.text = path.rstrip("/")
	for child in file_list.get_children():
		child.queue_free()
	var already_focused = false
	for dir_name in dir.get_directories():
		var button:Button = Button.new()
		button.text = dir_name
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.icon = load(str(ComicEditor.DIR_ICONS, str("folder.svg")))
#		button.focus_mode = Control.FOCUS_NONE
		file_list.add_child(button)
		button.pressed.connect(_on_folder_pressed.bind(dir_name))
		if not already_focused:
			button.grab_focus()
			already_focused = true
	for file_name in dir.get_files():
		if Comic.IMAGE_EXT.has(file_name.get_extension()):
			var button:Button = Button.new()
			button.text = file_name
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.icon = load(str(ComicEditor.DIR_ICONS, str("image.svg")))
#			button.focus_mode = Control.FOCUS_NONE
			file_list.add_child(button)
			button.pressed.connect(_on_file_pressed.bind(file_name))
			if not already_focused:
				button.grab_focus()
				already_focused = true


func _on_up_pressed():
	var path_parts:Array = path.split("/", false)
	path_parts.pop_back()
	open_dir("/".join(path_parts))

func _on_favorite_pressed():
	ComicEditor.save_setting("favorite_image_path", path)

func _on_address_submitted(new_text:String):
	open_dir(new_text)

func _on_folder_pressed(folder_name:String):
	open_dir(str(path, folder_name))

func _on_file_pressed(file_name:String):
	hide()
	callable.call(str(path, file_name))
