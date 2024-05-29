class_name ComicEditorImage
extends ComicImage

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "properties.svg")), "Image Properties", ComicEditor.MenuCommand.OPEN_PROPERTIES)
	menu.add_separator()
	menu.add_submenu_item("Layer", "layer")
	menu.add_separator()
	if fragment != "":
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "fragment.svg")), str(fragment.capitalize(), " Properties"), ComicEditor.MenuCommand.FRAGMENT_PROPERTIES)
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "clear_fragment.svg")), str("Remove from ", fragment.capitalize()), ComicEditor.MenuCommand.CLEAR_FRAGMENT)
	else:
		menu.add_submenu_item("Add to Fragment", "fragment")
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Remove Image", ComicEditor.MenuCommand.DELETE)

	# Fragment Submenu
	var menu_fragment:PopupMenu = PopupMenu.new()
	menu.add_child(menu_fragment)
	menu_fragment.index_pressed.connect(menu_fragment_index_pressed)
	menu_fragment.name = "fragment"
	#print(Comic.book.page.data)
	for key in Comic.book.page.fragments:
		if key != "":
			menu_fragment.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("fragment.svg"))), key.capitalize())
	menu_fragment.add_separator()
	menu_fragment.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("add.svg"))), "New Fragment")

	# Layer Submenu
	var menu_layer:PopupMenu = PopupMenu.new()
	menu.add_child(menu_layer)
	menu_layer.index_pressed.connect(menu_layer_index_pressed)
	menu_layer.name = "layer"
	for i in range(Comic.LAYERS.size() - 1, -1, -1):
		menu_layer.add_icon_item(load(str(ComicEditor.DIR_ICONS, "checked.svg" if i == layer else "unchecked.svg")), Comic.LAYERS[i])

func menu_fragment_index_pressed(index:int):
	if index < Comic.book.page.fragments.keys().size():
		fragment = Comic.book.page.fragments.keys()[index]
	else:
		# Add new fragment pressed
		Comic.book.page.new_fragment(ComicEditor.get_unique_array_item(Comic.book.page.fragments.keys(), "fragment_1"), self)
	Comic.book.open_properties = Comic.book.fragment_properties

func menu_layer_index_pressed(index:int):
	layer = Comic.LAYERS.size() - 1 - index
	rebuild(true)

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DELETE:
			remove()
		ComicEditor.MenuCommand.CLEAR_FRAGMENT:
			Comic.book.page.remove_o_from_fragment(self)
		ComicEditor.MenuCommand.FRAGMENT_PROPERTIES:
			Comic.book.open_properties = Comic.book.fragment_properties
		ComicEditor.MenuCommand.OPEN_PROPERTIES:
			Comic.book.open_properties = Comic.book.image_properties

func rebuild_widgets():
	var draw_layer:ComicWidgetLayer = Comic.book.page.layers[-1]
	draw_layer.clear()
	draw_layer.add_child(ComicWidthWidget.new(self))

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	Comic.book.grab(self, at_position - anchor)

func dropped(global_position:Vector2):
	dragged(global_position)
	
func dragged(global_position:Vector2):
	anchor = ComicEditor.snap(global_position)
	rebuild(true)

func has_point(point:Vector2) -> bool:
	return get_rect().has_point(point)

func draw_widgets(layer:ComicWidgetLayer):
	# Draw a box around the image
	layer.draw_polyline(PackedVector2Array([position, position + Vector2.RIGHT * size.x, position + size, position + Vector2.DOWN * size.y, position]), ComicEditorBalloon.WIDGET_COLOR, ComicWidget.THIN)
	
	# Draw a cross-hairs at the anchor
	layer.draw_line(anchor + Vector2.UP * ComicWidget.RADIUS, anchor + Vector2.DOWN * ComicWidget.RADIUS, ComicEditorBalloon.WIDGET_COLOR, ComicWidget.THICK)
	layer.draw_line(anchor + Vector2.LEFT * ComicWidget.RADIUS, anchor + Vector2.RIGHT * ComicWidget.RADIUS, ComicEditorBalloon.WIDGET_COLOR, ComicWidget.THICK)

func rebuild(_rebuild_subobjects:bool = false):
	super()
	Comic.book.page.redraw()

func remove():
	Comic.book.add_undo_step([ComicReversionParent.new(self, get_parent())])
	get_parent().remove_child(self)
	Comic.book.page.redraw(true)
	Comic.book.selected_element = null

func get_save_data() -> Dictionary:
	var r:Dictionary = _data.duplicate()
	if r.has("new_path"):
		# Save new image
		r.file_name = r.new_path.get_file().to_lower().replace(" ", "_").replace("-", "_")
		DirAccess.copy_absolute(r.new_path, str(Comic.DIR_IMAGES, r.file_name))
		r.erase("new_path")
	return r
	

func bump(direction:Vector2):
	#TODO: Figure out a way to not save on multiple bumps
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	anchor += direction * ComicEditor.snap_distance * ComicEditor.BUMP_AMOUNT
	rebuild(true)

func _on_key_pressed(event:InputEventKey):
	match event.keycode:
		KEY_UP:
			bump(Vector2.UP)
		KEY_DOWN:
			bump(Vector2.DOWN)
		KEY_LEFT:
			bump(Vector2.LEFT)
		KEY_RIGHT:
			bump(Vector2.RIGHT)
		KEY_DELETE:
			remove()
