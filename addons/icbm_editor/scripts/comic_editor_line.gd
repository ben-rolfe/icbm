class_name ComicEditorLine
extends ComicLine

func has_point(point:Vector2) -> bool:
	return get_point_segment(point, true) > -1

func _get_drag_data(_at_position):
	#TODO: Consider dragging the nearest point, and/or creating a point.
	return false

func get_point_segment(point:Vector2, check_widgets:bool = false) -> int:
	for i in data.points.size():
		var d0:float = point.distance_to(data.points[i])
		if check_widgets and d0 < ComicWidget.RADIUS:
			return i
		if i > 0:
			var l:float = data.points[i].distance_to(data.points[i - 1])
			var d1:float = point.distance_to(data.points[i - 1])
			if d0 < l and d1 < l and d0 * abs(sin((data.points[i] - data.points[i - 1]).angle_to(data.points[i] - point))) < fill_width / 2.0:
				return i - 1
	return -1
	
func remove():
	Comic.book.add_undo_step([ComicReversionParent.new(self, get_parent())])
	get_parent().remove_child(self)

func rebuild(_rebuild_sub_objects:bool = false):
	apply_data()
	Comic.book.page.redraw()

func rebuild_widgets():
	var draw_layer:ComicWidgetLayer = Comic.book.page.layers[-1]
	draw_layer.clear()
	for i in data.points.size():
		draw_layer.add_child(ComicLinePointWidget.new(self, i))

func after_reversion():
	rebuild()

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("properties.svg"))), "Line Properties", ComicEditor.MenuCommand.OPEN_PROPERTIES)
	menu.add_separator()
	menu.add_submenu_item("Presets", "preset")
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "add_line_point.svg")), "Add Point", ComicEditor.MenuCommand.ADD_PART)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Remove Line", ComicEditor.MenuCommand.DELETE)

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

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DELETE:
			remove()
			Comic.book.selected_element = null
			Comic.book.page.redraw(true)
			Comic.book.page.rebuild_widgets()
		ComicEditor.MenuCommand.ADD_PART:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			var index = get_point_segment(Comic.book.menu.position)
			if index > -1:
				data.points.insert(index + 1, Comic.book.snap_and_contain(Comic.book.menu.position))
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
