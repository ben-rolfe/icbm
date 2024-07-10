class_name ComicEditorBackground
extends ComicBackground

# The comic editor background doesn't really do much involving the background.
# It catches the generic "not clicking on anything" clicks and handles the general right-click menu.

#var waiting_for_scan:bool
#var timer:float

var _data:Dictionary = {}
var undo_refcount:int

func _get_drag_data(at_position:Vector2):
	if Comic.book.selected_element != self and Comic.book.selected_element.has_method("_get_drag_data"):
		Comic.book.selected_element._get_drag_data(at_position)

func _gui_input(event:InputEvent):
	if event is InputEventMouseButton and event.pressed:
		var o:CanvasItem
		if Comic.book.page.hovered_hotspots.size() > 0:
			o = Comic.book.page.hovered_hotspots[-1]
		else:
			o = Comic.book.page.get_o_at_point(get_viewport().get_mouse_position())
		if o != null:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.is_double_click():
					Comic.book.double_clicked(o, event)
				else:
					Comic.book.left_clicked(o, event)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				Comic.book.right_clicked(o, event)

func add_menu_items(menu:PopupMenu):
	for i in Comic.editor_menu_items.size():
		if i > 0:
			menu.add_separator()
		for j in Comic.editor_menu_items[i].size():
			var item:Dictionary = Comic.editor_menu_items[i][j]
			if item.has("submenu_id"):
				if item.submenu_build.call(item.submenu_id, item.submenu_click):
					# Submenu built successfully
					menu.add_submenu_item(item.text, item.submenu_id)
				else:
					# Submenu failed to build - we still add the menu item, but disable it.
					# This lets users get accustomed to the existence of the submenu, even before it has content.
					menu.add_item(item.text)
					menu.set_item_disabled(-1, true)
			else:
				menu.add_icon_item(load(item.icon_path), item.text)
				menu.set_item_metadata(menu.item_count - 1, item.callable)

func menu_command_pressed(index:int):
	Comic.book.menu.get_item_metadata(index).call()

func import_new_bg(path:String):
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	_data.new_bg_path = path
	rebuild()
	Comic.book.page.redraw()

func import_new_image(path:String):
	Comic.book.page.add_image({"new_path":path})

func rebuild():
	if _data.has("new_bg_path"):
		# Using an image that isn't in the resources, yet - load it from the filesystem 
		texture = ImageTexture.create_from_image(Image.load_from_file(_data.new_bg_path))
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
	if _data.get("new_bg_path", "") != "":
		print("Save background")
		# Delete old images and .import files
		var dir:DirAccess = DirAccess.open(Comic.DIR_STORY)
		var path_base:String = str(Comic.book.page.bookmark, "." if Comic.book.page.bookmark.contains("/") else "/_.")
		for ext in Comic.IMAGE_EXT:
			dir.remove(str(path_base, ext))
			dir.remove(str(path_base, ext, ".import"))

		# Save new image
		var save_path:String = str(Comic.DIR_STORY, path_base, _data.new_bg_path.get_extension().to_lower())
		if dir != null:
			dir.copy(_data.new_bg_path, save_path)



