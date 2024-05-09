class_name ComicEditorLine
extends ComicLine

func has_point(point:Vector2) -> bool:
	return get_point_segment(point, true) > -1

func _get_drag_data(_at_position):
	#TODO: Consider dragging the nearest point, and/or creating a point.
	return false

func get_point_segment(point:Vector2, check_widgets:bool = false) -> int:
	for i in _data.points.size():
		var d0:float = point.distance_to(_data.points[i])
		if check_widgets and d0 < ComicWidget.RADIUS:
			return i
		if i > 0:
			var l:float = _data.points[i].distance_to(_data.points[i - 1])
			var d1:float = point.distance_to(_data.points[i - 1])
			if d0 < l and d1 < l and d0 * abs(sin((_data.points[i] - _data.points[i - 1]).angle_to(_data.points[i] - point))) < fill_width / 2.0:
				return i - 1
	return -1
	
func remove():
	Comic.book.add_undo_step([ComicReversionParent.new(self, get_parent())])
	get_parent().remove_child(self)
	Comic.book.selected_element = null
	Comic.book.page.redraw(true)
	Comic.book.page.rebuild_widgets()


func rebuild(_rebuild_sub_objects:bool = false):
	apply_data()
	Comic.book.page.redraw()

func rebuild_widgets():
	var draw_layer:ComicWidgetLayer = Comic.book.page.layers[-1]
	draw_layer.clear()
	for i in _data.points.size():
		draw_layer.add_child(ComicLinePointWidget.new(self, i))

func after_reversion():
	rebuild()

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("properties.svg"))), "Line Properties", ComicEditor.MenuCommand.OPEN_PROPERTIES)
	menu.add_separator()
	menu.add_submenu_item("Presets", "preset")
	menu.add_separator()
	if fragment != "":
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("fragment.svg"))), str(fragment.capitalize(), " Properties"), ComicEditor.MenuCommand.FRAGMENT_PROPERTIES)
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("clear_fragment.svg"))), str("Remove from ", fragment.capitalize()), ComicEditor.MenuCommand.CLEAR_FRAGMENT)
	else:
		menu.add_submenu_item("Add to Fragment", "fragment")
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "add_line_point.svg")), "Add Point", ComicEditor.MenuCommand.ADD_PART)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Remove Line", ComicEditor.MenuCommand.DELETE)

	# Fragment Submenu
	var menu_fragment:PopupMenu = PopupMenu.new()
	menu.add_child(menu_fragment)
	menu_fragment.index_pressed.connect(menu_fragment_index_pressed)
	menu_fragment.name = "fragment"
	for key in Comic.book.page.fragments:
		if key != "":
			menu_fragment.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("fragment.svg"))), key.capitalize())
	menu_fragment.add_separator()
	menu_fragment.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("add.svg"))), "New Fragment")

	# Preset Submenu
	var menu_preset:PopupMenu = PopupMenu.new()
	menu.add_child(menu_preset)
	menu_preset.hide_on_checkable_item_selection = false
	menu_preset.index_pressed.connect(_menu_preset_index_pressed.bind(menu_preset))
	menu_preset.name = "preset"
	for key in Comic.book.presets.line:
		if key != "":
			menu_preset.add_check_item(key.capitalize())
			menu_preset.set_item_checked(-1, presets.has(key))
	menu_preset.add_separator()
	menu_preset.add_item("Manage Presets / Defaults")

func menu_fragment_index_pressed(index:int):
	if index < Comic.book.page.fragments.keys().size():
		fragment = Comic.book.page.fragments.keys()[index]
	else:
		# Add new fragment pressed
		Comic.book.page.new_fragment(ComicEditor.get_unique_array_item(Comic.book.page.fragments.keys(), "fragment_1"), self)
	Comic.book.open_properties = Comic.book.fragment_properties
	
func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.CLEAR_FRAGMENT:
			Comic.book.page.remove_o_from_fragment(self)
		ComicEditor.MenuCommand.FRAGMENT_PROPERTIES:
			Comic.book.open_properties = Comic.book.fragment_properties
		ComicEditor.MenuCommand.DELETE:
			remove()
		ComicEditor.MenuCommand.ADD_PART:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			var index = get_point_segment(Comic.book.menu.position)
			if index > -1:
				_data.points.insert(index + 1, Comic.book.snap_and_contain(Comic.book.menu.position))
			Comic.book.page.redraw(true)
			Comic.book.page.rebuild_widgets()


func _menu_preset_index_pressed(index:int, menu_preset:PopupMenu):
	if index == menu_preset.item_count - 1:
		# Manage Presets was selected
		Comic.book.open_presets_manager("line")
	else:
		# A preset was selected
		Comic.book.add_undo_step([ComicReversionData.new(self)])
		var key:String = Comic.book.presets.line.keys()[index + 1]
		if presets.has(key):
			presets.erase(key)
			menu_preset.set_item_checked(index, false)
		else:
			presets.push_back(key)
			menu_preset.set_item_checked(index, true)
		_scrub_redundant_data()
		rebuild(true)
		
func _scrub_redundant_data():
	print("TODO: Scrub redundant data")

func get_save_data() -> Dictionary:
	return _data.duplicate()

func bump(direction:Vector2):
	#TODO: Figure out a way to not save on multiple bumps
	Comic.book.add_undo_step([ComicReversionData.new(self)])
#	anchor += direction * Comic.px_per_unit * ComicEditor.BUMP_AMOUNT
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
