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

func rebuild():
	if _data.has("new_bg_path"):
		# Using an image that isn't in the resources, yet - load it from the filesystem 
		texture = ImageTexture.create_from_image(get_fullscreen_image(_data.new_bg_path))
		Comic.book.page.redraw()
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
	if _data.has("new_bg_path"):
		print("Save background")
		# Delete old images and .import files
		var dir:DirAccess = DirAccess.open(Comic.DIR_STORY)
		var path_base:String = str(Comic.book.page.bookmark, "." if Comic.book.page.bookmark.contains("/") else "/_.")
		for ext in Comic.IMAGE_EXT:
			dir.remove(str(path_base, ext))
			dir.remove(str(path_base, ext, ".import"))

		# Save new image
		if dir != null:
			if Comic.book.image_quality < 0:
				# Image quality of -1 means keep the original image format, but we still need to make it fullscreen.
				var ext:String = _data.new_bg_path.get_extension().to_lower()
				match ext:
					"jpg", "jpeg":
						get_fullscreen_image(_data.new_bg_path).save_jpg(str(Comic.DIR_STORY, path_base, "jpg"))
					"png":
						get_fullscreen_image(_data.new_bg_path).save_png(str(Comic.DIR_STORY, path_base, "png"))
					"webp", "svg":
						get_fullscreen_image(_data.new_bg_path).save_webp(str(Comic.DIR_STORY, path_base, "webp"))
			else:
				# Image quality of 0+ means we convert to webp - quality is already handled in the get_fullscreen_image method, so we don't apply compression with the save.
				get_fullscreen_image(_data.new_bg_path).save_webp(str(Comic.DIR_STORY, path_base, "webp"))


func get_fullscreen_image(path) -> Image:
	var loaded_image:Image
	var image_format:Image.Format = Image.FORMAT_RGB8
	if path != "":
		loaded_image = Image.load_from_file(path)
		if Comic.book.image_quality >= 0:
			#Image requires conversion
			var webp_buffer:PackedByteArray
			loaded_image = Image.load_from_file(path)
			if Comic.book.image_quality >= 100:
				# Image quality of 100 (or greater) means lossless webp
				webp_buffer = loaded_image.save_webp_to_buffer()
			else:
				# Image quality of 0-99 means lossy webp
				webp_buffer = loaded_image.save_webp_to_buffer(true, Comic.book.image_quality / 100.0)
			loaded_image.load_webp_from_buffer(webp_buffer)
		if loaded_image != null:
			image_format = loaded_image.get_format()

	var fullscreen_image:Image = Image.create(int(Comic.size.x), int(Comic.size.y), false, image_format)
	if loaded_image != null:
		fullscreen_image.blit_rect(loaded_image, Rect2i(0, 0, min(int(Comic.size.x), loaded_image.get_width()), min(int(Comic.size.y), loaded_image.get_height())), Vector2i.ZERO)
	return fullscreen_image

func clear():
	_data.new_bg_path = ""
	rebuild()
