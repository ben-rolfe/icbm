class_name ComicEditorBackground
extends ComicBackground

# The comic editor background doesn't really do much involving the background.
# It catches the generic "not clicking on anything" clicks and handles the general right-click menu.

#var waiting_for_scan:bool
#var timer:float

var data:Dictionary = {}
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
	if Comic.book.page.data.fragments.size() > 0:
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
	print(Comic.book.page.data)
	for key in Comic.book.page.data.fragments:
		if key != "":
			menu_fragment.add_item(key.capitalize())

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.OPEN_PROPERTIES:
			Comic.book.open_properties = Comic.book.page_properties

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
	Comic.book.fragment_properties.key = Comic.book.page.data.fragments.keys()[index]
	Comic.book.open_properties = Comic.book.fragment_properties

func import_new_image(path:String):
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	data.new_image_path = path
	rebuild()
	Comic.book.page.redraw()

func rebuild():
	if data.has("new_image_path"):
#		texture = null
#		texture = load(data.new_image_path)
		texture = ImageTexture.create_from_image(Image.load_from_file(data.new_image_path))
	else:
		super()

func after_reversion():
	rebuild()

func save():
	if data.get("new_image_path", "") != "":
		print("Save background")
		# Delete old images and .import files
		var dir:DirAccess = DirAccess.open(Comic.DIR_STORY)
		var path_base:String = str(Comic.book.page.bookmark, "." if Comic.book.page.bookmark.contains("/") else "/_.")
		for ext in Comic.IMAGE_EXT:
			dir.remove(str(path_base, ext))
			dir.remove(str(path_base, ext, ".import"))

		# Save new image
		var save_path:String = str(Comic.DIR_STORY, path_base, data.new_image_path.get_extension().to_lower())
		print(data.new_image_path)
		print(save_path)
		if dir != null:
			print(dir.copy(data.new_image_path, save_path))

