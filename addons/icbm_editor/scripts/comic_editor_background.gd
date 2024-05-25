class_name ComicEditorBackground
extends ComicBackground

# The comic editor background doesn't really do much involving the background.
# It catches the generic "not clicking on anything" clicks and handles the general right-click menu.

#var waiting_for_scan:bool
#var timer:float

var _data:Dictionary = {}
var undo_refcount:int

func _get_drag_data(at_position:Vector2):
	if Comic.book.selected_element != self and Comic.book.selected_element is Control:
		Comic.book.selected_element._get_drag_data(at_position)

func _gui_input(event:InputEvent):
	if event is InputEventMouseButton and event.pressed:
		var o = Comic.book.page.get_o_at_point(get_viewport().get_mouse_position())
		if o != null:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.is_double_click():
					Comic.book.double_clicked(o, event)
				else:
					Comic.book.left_clicked(o, event)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				Comic.book.right_clicked(o, event)

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "properties.svg")), "Chapter Properties" if Comic.book.page_properties.is_chapter else "Page Properties", ComicEditor.MenuCommand.OPEN_PROPERTIES)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "properties.svg")), "Book Properties", ComicEditor.MenuCommand.BOOK_PROPERTIES)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "settings.svg")), "Editor Settings", ComicEditor.MenuCommand.OPEN_SETTINGS)
	if Comic.book.page.fragments.size() > 0:
		menu.add_submenu_item("Fragment Properties", "fragment")
	else:
		# We show the fragment properties item even if there are no fragments, so that the user can become familiar with where it is.
		menu.add_item("Fragment Properties")
		menu.set_item_disabled(-1, true)		
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "shape_balloon.svg")), "Add Balloon", ComicEditor.MenuCommand.ADD_BALLOON)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "shape_box.svg")), "Add Caption", ComicEditor.MenuCommand.ADD_CAPTION)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "label.svg")), "Add Kaboom", ComicEditor.MenuCommand.ADD_KABOOM)
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "button.svg")), "Add Button", ComicEditor.MenuCommand.ADD_BUTTON)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "hotspot.svg")), "Add Hotspot", ComicEditor.MenuCommand.ADD_HOTSPOT)
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "image.svg")), "Change Background", ComicEditor.MenuCommand.CHANGE_BACKGROUND)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "frame_border.svg")), "Add Border Line", ComicEditor.MenuCommand.ADD_LINE)
	menu.add_submenu_item("Add Image", "image")
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "note.svg")), "Add Note", ComicEditor.MenuCommand.ADD_NOTE)
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "undo.svg")), str("Undo (", OS.get_keycode_string(int(ComicEditor.MenuCommand.UNDO)) , ")"), ComicEditor.MenuCommand.UNDO)
	if Comic.book.undo_steps.size() == 0:
		menu.set_item_disabled(-1, true)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "redo.svg")), str("Redo (", OS.get_keycode_string(int(ComicEditor.MenuCommand.REDO)) , ")"), ComicEditor.MenuCommand.REDO)
	if Comic.book.redo_steps.size() == 0:
		menu.set_item_disabled(-1, true)
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "save.svg")), str("Save (", OS.get_keycode_string(int(ComicEditor.MenuCommand.SAVE)) , ")"), ComicEditor.MenuCommand.SAVE)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "save.svg")), str("Save and Quit (", OS.get_keycode_string(int(ComicEditor.MenuCommand.SAVE_AND_QUIT)) , ")"), ComicEditor.MenuCommand.SAVE_AND_QUIT)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), str("Quit Without Saving (", OS.get_keycode_string(int(ComicEditor.MenuCommand.QUIT_WITHOUT_SAVING)) , ")"), ComicEditor.MenuCommand.QUIT_WITHOUT_SAVING)

	# Fragment Submenu
	var menu_fragment:PopupMenu = PopupMenu.new()
	menu.add_child(menu_fragment)
	menu_fragment.index_pressed.connect(menu_fragment_index_pressed)
	menu_fragment.name = "fragment"
	for key in Comic.book.page.fragments:
		if key != "":
			menu_fragment.add_item(key.capitalize())

	# Fragment Submenu
	var menu_image:PopupMenu = PopupMenu.new()
	menu.add_child(menu_image)
	menu_image.index_pressed.connect(menu_image_index_pressed)
	menu_image.name = "image"
	for file_name in DirAccess.get_files_at(Comic.DIR_IMAGES):
		menu_image.add_icon_item(load(str(ComicEditor.DIR_ICONS, "image.svg")), file_name)
		menu_image.set_item_metadata(-1, file_name)
	menu_image.add_separator()
	menu_image.add_icon_item(load(str(ComicEditor.DIR_ICONS, "add.svg")), "Import image")

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.OPEN_PROPERTIES:
			Comic.book.open_properties = Comic.book.page_properties
		ComicEditor.MenuCommand.BOOK_PROPERTIES:
			Comic.book.open_properties = Comic.book.book_properties
		ComicEditor.MenuCommand.OPEN_SETTINGS:
			Comic.book.open_properties = Comic.book.settings_properties

		ComicEditor.MenuCommand.ADD_BALLOON:
			Comic.book.page.add_balloon({"with_tail":true})
		ComicEditor.MenuCommand.ADD_CAPTION:
			Comic.book.page.add_balloon({"presets":["caption"]})
		ComicEditor.MenuCommand.ADD_KABOOM:
			Comic.book.page.add_label()

		ComicEditor.MenuCommand.ADD_BUTTON:
			Comic.book.page.add_button()
		ComicEditor.MenuCommand.ADD_HOTSPOT:
			Comic.book.page.add_hotspot()

		ComicEditor.MenuCommand.CHANGE_BACKGROUND:
			ComicEditorImageExplorer.open(import_new_image)
		ComicEditor.MenuCommand.ADD_LINE:
			Comic.book.page.add_line()

		ComicEditor.MenuCommand.ADD_NOTE:
			Comic.book.page.add_note()

		ComicEditor.MenuCommand.UNDO:
			Comic.book.undo()
		ComicEditor.MenuCommand.REDO:
			Comic.book.redo()

		ComicEditor.MenuCommand.SAVE:
			Comic.book.save()
		ComicEditor.MenuCommand.SAVE_AND_QUIT:
			Comic.book.save(true)
		ComicEditor.MenuCommand.QUIT_WITHOUT_SAVING:
			Comic.request_quit()

func menu_fragment_index_pressed(index:int):
	Comic.book.fragment_properties.key = Comic.book.page.fragments.keys()[index]
	Comic.book.open_properties = Comic.book.fragment_properties

func menu_image_index_pressed(index:int):
	pass

func import_new_image(path:String):
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	_data.new_image_path = path
	rebuild()
	Comic.book.page.redraw()

func rebuild():
	if _data.has("new_image_path"):
		# Using an image that isn't in the resources, yet - load it from the filesystem 
		texture = ImageTexture.create_from_image(Image.load_from_file(_data.new_image_path))
	else:
		super()

func _draw():
	if ComicEditor.grid_on:
		# Draw Grid
		var image = Image.new()
		var base_lines:PackedVector2Array = PackedVector2Array()
		var strong_lines:PackedVector2Array = PackedVector2Array()
		var feature_lines:PackedVector2Array = PackedVector2Array()
		for i in int(Comic.size.x / ComicEditor.snap_distance.x) + 1:
			var lines = base_lines
			var relative_pos = float(i * ComicEditor.snap_distance.x) / Comic.size.x
			if is_zero_approx(fposmod(relative_pos * 4, 1)) or is_zero_approx(fposmod(relative_pos * 3, 1)):
				lines = feature_lines
			elif i % 10 == 0:
				lines = strong_lines
			lines.append(Vector2(i * ComicEditor.snap_distance.x, 0))
			lines.append(Vector2(i * ComicEditor.snap_distance.x, Comic.size.y))
		for i in int(Comic.size.y / ComicEditor.snap_distance.y) + 1:
			var lines = base_lines
			var relative_pos = float(i * ComicEditor.snap_distance.y) / Comic.size.y
			if is_zero_approx(fposmod(relative_pos * 4, 1)) or is_zero_approx(fposmod(relative_pos * 3, 1)):
				lines = feature_lines
			elif i % 10 == 0:
				lines = strong_lines
			lines.append(Vector2(0, i * ComicEditor.snap_distance.y))
			lines.append(Vector2(Comic.size.x, i * ComicEditor.snap_distance.y))
		draw_multiline(base_lines, ComicEditor.snap_color, 1)
		draw_multiline(strong_lines, ComicEditor.snap_color_strong, 1)
		draw_multiline(feature_lines, ComicEditor.snap_color_feature, 1)

func after_reversion():
	rebuild()

func save():
	if _data.get("new_image_path", "") != "":
		print("Save background")
		# Delete old images and .import files
		var dir:DirAccess = DirAccess.open(Comic.DIR_STORY)
		var path_base:String = str(Comic.book.page.bookmark, "." if Comic.book.page.bookmark.contains("/") else "/_.")
		for ext in Comic.IMAGE_EXT:
			dir.remove(str(path_base, ext))
			dir.remove(str(path_base, ext, ".import"))

		# Save new image
		var save_path:String = str(Comic.DIR_STORY, path_base, _data.new_image_path.get_extension().to_lower())
		#print(_data.new_image_path)
		#print(save_path)
		if dir != null:
			print(dir.copy(_data.new_image_path, save_path))

