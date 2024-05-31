class_name ComicEditorHotspot
extends ComicHotspot

var offset_points:Array

func draw_shape(draw_layer:ComicLayer):
	if points.size() > 1:
		offset_points = points.duplicate()
		for i in offset_points.size():
			offset_points[i] += anchor
		offset_points.push_back(offset_points[0])
		draw_layer.draw_colored_polygon(offset_points, ComicEditor.hotspot_color_fill)
		draw_layer.draw_polyline(offset_points, ComicEditor.hotspot_color_edge, 1, true)

func draw_widgets(layer:ComicWidgetLayer):
	# Draw a cross-hairs at the anchor
	layer.draw_line(anchor + Vector2.UP * ComicWidget.RADIUS, anchor + Vector2.DOWN * ComicWidget.RADIUS, ComicEditorBalloon.WIDGET_COLOR, ComicWidget.THICK)
	layer.draw_line(anchor + Vector2.LEFT * ComicWidget.RADIUS, anchor + Vector2.RIGHT * ComicWidget.RADIUS, ComicEditorBalloon.WIDGET_COLOR, ComicWidget.THICK)

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	Comic.book.grab(self, at_position - anchor)

func dropped(global_position:Vector2):
	dragged(global_position)
	
func dragged(global_position:Vector2):
	# convert position to units
	anchor = ComicEditor.snap(global_position)
	rebuild(true)

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "properties.svg")), "Hotspot Properties", ComicEditor.MenuCommand.OPEN_PROPERTIES)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "add_line_point.svg")), "Add Point", ComicEditor.MenuCommand.ADD_PART)
	menu.add_separator()
	if fragment != "":
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "fragment.svg")), str(fragment.capitalize(), " Properties"), ComicEditor.MenuCommand.FRAGMENT_PROPERTIES)
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "clear_fragment.svg")), str("Remove from ", fragment.capitalize()), ComicEditor.MenuCommand.CLEAR_FRAGMENT)
	else:
		menu.add_submenu_item("Add to Fragment", "fragment")
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Remove Hotspot", ComicEditor.MenuCommand.DELETE)

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

func menu_fragment_index_pressed(index:int):
	if index < Comic.book.page.fragments.keys().size():
		fragment = Comic.book.page.fragments.keys()[index]
	else:
		# Add new fragment pressed
		Comic.book.page.new_fragment(ComicEditor.get_unique_array_item(Comic.book.page.fragments.keys(), "fragment_1"), self)
	Comic.book.open_properties = Comic.book.fragment_properties

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.ADD_PART:
			var clicked_point:Vector2 = Vector2(Comic.book.menu.position) - anchor
			var best_distance_squared:float = INF
			var best_point:Vector2 = Vector2.ZERO
			var best_i:int = 0
			for i in points.size():
				var point:Vector2 = Geometry2D.get_closest_point_to_segment(clicked_point, points[i], points[i - 1])
				var distance_squared:float = point.distance_squared_to(clicked_point)
				if distance_squared < best_distance_squared:
					best_distance_squared = distance_squared
					best_i = i
					best_point = point
			if best_point.is_equal_approx(points[best_i]) or best_point.is_equal_approx(points[best_i - 1]):
				# The closest point to the click is an existing point - go halfway along the line that it's an endpoint of, instead.
				best_point = (points[best_i] + points[best_i - 1]) * 0.5
			if best_i == 0:
				points.push_back(best_point)
			else:
				points.insert(best_i, best_point)
			rebuild()
			rebuild_widgets()
		ComicEditor.MenuCommand.DELETE:
			remove()
		ComicEditor.MenuCommand.CLEAR_FRAGMENT:
			Comic.book.page.remove_o_from_fragment(self)
		ComicEditor.MenuCommand.FRAGMENT_PROPERTIES:
			Comic.book.open_properties = Comic.book.fragment_properties
		ComicEditor.MenuCommand.OPEN_PROPERTIES:
			Comic.book.open_properties = Comic.book.hotspot_properties

func rebuild(_rebuild_subobjects:bool = false):
	super()
	Comic.book.page.redraw()

func rebuild_widgets():
	var draw_layer:ComicWidgetLayer = Comic.book.page.layers[-1]
	draw_layer.clear()
	for i in points.size():
		draw_layer.add_child(ComicLinePointWidget.new(self, i))

func activate():
	# In case we somehow activate the hotspot in edit mode, we ignore it 
	pass

func remove():
	Comic.book.add_undo_step([ComicReversionParent.new(self, get_parent())])
	get_parent().remove_child(self)
	Comic.book.page.exit_hotspot(self)
	Comic.book.page.redraw(true)
	Comic.book.selected_element = null

func get_save_data() -> Dictionary:
	return _data.duplicate()

func bump(direction:Vector2):
	#TODO: Figure out a way to not save on multiple bumps
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	anchor += direction * ComicEditor.snap_distance * ComicEditor.BUMP_AMOUNT
	rebuild(true)
