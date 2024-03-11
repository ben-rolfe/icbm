class_name ComicEditorBackground
extends ComicBackground

# The comic editor background doesn't really do much involving the background.
# It catches the generic "not clicking on anything" clicks and handles the general right-click menu.

#var waiting_for_scan:bool
#var timer:float

var data:Dictionary = {}
var undo_refcount:int

func _gui_input(event:InputEvent):
	var o:Variant
	if event is InputEventMouseButton:
		if event.pressed:
			o = Comic.book.page.get_o_at_point(event.global_position)
	if o != null:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_double_click():
				Comic.book.double_clicked(o, event)
			else:
				Comic.book.left_clicked(o, event)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			Comic.book.right_clicked(o, event)
	else:
		super(event)

func _get_drag_data(at_position:Vector2):
	if Comic.book.selected_element != self and Comic.book.selected_element is Control:
		Comic.book.selected_element._get_drag_data(at_position)

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "properties.svg")), "Chapter Properties" if Comic.book.page_properties.is_chapter else "Page Properties", ComicEditor.MenuCommand.OPEN_PROPERTIES)
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "shape_balloon.svg")), "Add Balloon", ComicEditor.MenuCommand.ADD_BALLOON)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "shape_box.svg")), "Add Caption", ComicEditor.MenuCommand.ADD_CAPTION)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "label.svg")), "Add Label", ComicEditor.MenuCommand.ADD_LABEL)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "frame_border.svg")), "Add Frame Border", ComicEditor.MenuCommand.ADD_LINE)
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "image.svg")), "Change Background", ComicEditor.MenuCommand.CHANGE_BACKGROUND)
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

func menu_command_pressed(id:int):
	match id:

		ComicEditor.MenuCommand.ADD_BALLOON:
			Comic.book.page.add_balloon({"with_tail":true})

		ComicEditor.MenuCommand.ADD_CAPTION:
			Comic.book.page.add_balloon({"presets":["caption"]})

		ComicEditor.MenuCommand.ADD_LABEL:
			Comic.book.page.add_label()
			
		ComicEditor.MenuCommand.ADD_LINE:
			Comic.book.page.add_line()
			
		ComicEditor.MenuCommand.CHANGE_BACKGROUND:
			ComicEditorImageExplorer.open(import_new_image)

		ComicEditor.MenuCommand.OPEN_PROPERTIES:
			Comic.book.open_properties = Comic.book.page_properties

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

func import_new_image(path:String):
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	data.new_image_path = path
	rebuild()
	Comic.book.page.redraw()

func rebuild():
	if data.has("new_image_path"):
		texture = null
		print(data.new_image_path)
		texture = load(data.new_image_path)
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

