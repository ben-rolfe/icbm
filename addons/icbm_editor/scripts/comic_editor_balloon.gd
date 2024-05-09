class_name ComicEditorBalloon
extends ComicBalloon

const WIDGET_COLOR:Color = Color.RED

var long_r_squared:float
var bounds_rect:Rect2i

func _init(data:Dictionary, page:ComicPage):
	#if data.has("ref"):
		#Comic.book.safety_check_unique_ref(data.ref)
	super(data, page)

	#_default_edge = Comic.edges.values()[0]
	#_default_shape = Comic.shapes.values()[0]

	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
func apply_data():
	super()
	# If the balloon contains a link, the mouse_filter will have been set to receive inputs, which we don't want in the editor
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# We do some calculations now to speed up has_point
	if shape is ComicBoxShape:
		bounds_rect = Rect2i(center_point - frame_half_size, frame_half_size * 2)
	else:
		# Get the long radius
		long_r_squared = max(shape.get_edge_offset(self, 0).x, shape.get_edge_offset(self, TAU / 4).y)
		# Square it for efficiency, so we can compare it with the results of squared distance methods
		long_r_squared *= long_r_squared

func rebuild(rebuild_subobjects:bool = false):
	super(rebuild_subobjects)
	Comic.book.page.redraw()

func after_reversion():
	rebuild(true)

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	Comic.book.grab(self, at_position - anchor)

func dropped(global_position:Vector2):
	dragged(global_position)
	
func dragged(global_position:Vector2):
	# convert position to units
	anchor = ComicEditor.snap(global_position)
	for oids in tail_backlinks:
		Comic.book.page.os[oids.x].rebuild_tail(oids.y)
	rebuild(true)

func has_point(point:Vector2) -> bool:
	return shape.has_point(self, point)

func rebuild_widgets():
	var draw_layer:ComicWidgetLayer = Comic.book.page.layers[-1]
	draw_layer.clear()
	if width > 0:
		draw_layer.add_child(ComicBalloonWidthWidget.new(self))
	for tail_oid in tails:
		add_tail_widgets(tails[tail_oid], draw_layer)
	for oids in tail_backlinks:
		add_tail_widgets(Comic.book.page.os[oids.x].tails[oids.y], draw_layer)

func add_tail_widgets(tail:ComicTail, draw_layer:ComicWidgetLayer):
	var tail_start_widget:ComicTailStartWidget = ComicTailStartWidget.new(tail)
	draw_layer.add_child(tail_start_widget)
	if tail_start_widget.has_custom_vector:
		draw_layer.add_child(ComicVectorSubwidget.new(tail_start_widget))
	var tail_end_widget:ComicTailEndWidget = ComicTailEndWidget.new(tail)
	draw_layer.add_child(tail_end_widget)
	if tail_end_widget.has_custom_vector:
		draw_layer.add_child(ComicVectorSubwidget.new(tail_end_widget))

func delete():
	# First remove any backlinked tails
	for oids in tail_backlinks:
		Comic.book.page.os[oids.x].delete_tail(oids.y)
	get_parent().remove_child(self)

func delete_tail(oid:int):
	tails.erase(oid)
	tail_data.erase(oid)

func draw_widgets(layer:ComicWidgetLayer):
	# Draw a box around the textbox
	layer.draw_polyline(PackedVector2Array([position, position + Vector2.RIGHT * size.x, position + size, position + Vector2.DOWN * size.y, position]), ComicEditorBalloon.WIDGET_COLOR, ComicWidget.THIN)
	
	# Draw a cross-hairs at the anchor
	layer.draw_line(anchor + Vector2.UP * ComicWidget.RADIUS, anchor + Vector2.DOWN * ComicWidget.RADIUS, ComicEditorBalloon.WIDGET_COLOR, ComicWidget.THICK)
	layer.draw_line(anchor + Vector2.LEFT * ComicWidget.RADIUS, anchor + Vector2.RIGHT * ComicWidget.RADIUS, ComicEditorBalloon.WIDGET_COLOR, ComicWidget.THICK)

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "properties.svg")), "Balloon Properties", ComicEditor.MenuCommand.OPEN_PROPERTIES)
	menu.add_separator()
	menu.add_submenu_item("Presets", "preset")
	menu.add_submenu_item("Style", "style")
	menu.add_submenu_item("Size", "size")
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("dice_", randi_range(1, 6), ".svg"))), "Rerandomize Edge", ComicEditor.MenuCommand.RANDOMIZE)
	if not edge_style.is_randomized:
		menu.set_item_disabled(-1, true)
	menu.add_separator()
	menu.add_submenu_item("Layer", "layer")
	menu.add_separator()
	if fragment != "":
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "fragment.svg")), str(fragment.capitalize(), " Properties"), ComicEditor.MenuCommand.FRAGMENT_PROPERTIES)
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "clear_fragment.svg")), str("Remove from ", fragment.capitalize()), ComicEditor.MenuCommand.CLEAR_FRAGMENT)
	else:
		menu.add_submenu_item("Add to Fragment", "fragment")
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "shape_balloon.svg")), "Add Tail", ComicEditor.MenuCommand.ADD_TAIL)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Remove Balloon", ComicEditor.MenuCommand.DELETE)

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

	# Preset Submenu
	var menu_preset:PopupMenu = PopupMenu.new()
	menu.add_child(menu_preset)
	menu_preset.hide_on_checkable_item_selection = false
	menu_preset.index_pressed.connect(_menu_preset_index_pressed.bind(menu_preset))
	menu_preset.name = "preset"
	for key in Comic.book.presets.balloon:
		if key != "":
			menu_preset.add_check_item(key.capitalize())
			menu_preset.set_item_checked(-1, presets.has(key))
	menu_preset.add_separator()
	menu_preset.add_item("Manage Presets / Defaults")

	# Size Submenu
	var menu_size:PopupMenu = PopupMenu.new()
	menu.add_child(menu_size)
	menu_size.id_pressed.connect(menu.id_pressed.get_connections()[0].callable)
	menu_size.name = "size"
	menu_size.add_icon_item(load(str(ComicEditor.DIR_ICONS, "collapse.svg")), "Preserve Width" if collapse else "Collapse Width", ComicEditor.MenuCommand.TOGGLE_COLLAPSE)
	menu_size.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("width.svg"))), "Clear Fixed Width" if width > 0 else "Fixed Width", ComicEditor.MenuCommand.TOGGLE_WIDTH_CONTROL)
	menu_size.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("height.svg"))), "Clear Fixed Height" if height > 0 else "Fixed Height", ComicEditor.MenuCommand.TOGGLE_HEIGHT_CONTROL)

	# Shape and Edge Style Submenu
	var menu_style:PopupMenu = PopupMenu.new()
	menu.add_child(menu_style)
	menu_style.index_pressed.connect(menu_style_index_pressed)
	menu_style.name = "style"
	for key in Comic.edge_styles[shape.id]:
		menu_style.add_icon_item(Comic.edge_styles[shape.id][key].editor_icon, Comic.edge_styles[shape.id][key].editor_name)
		if key == edge_style.id:
			menu_style.set_item_disabled(-1, true)
	menu_style.add_separator("Shape")
	for key in Comic.shapes:
		menu_style.add_icon_item(Comic.shapes[key].editor_icon, Comic.shapes[key].editor_name)
		if key == shape.id:
			menu_style.set_item_disabled(-1, true)

func menu_fragment_index_pressed(index:int):
	if index < Comic.book.page.fragments.keys().size():
		fragment = Comic.book.page.fragments.keys()[index]
	else:
		# Add new fragment pressed
		Comic.book.page.new_fragment(ComicEditor.get_unique_array_item(Comic.book.page.fragments.keys(), "fragment_1"), self)
	Comic.book.open_properties = Comic.book.fragment_properties
		
func menu_style_index_pressed(index:int):
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	if index > Comic.edge_styles[shape.id].size():
		index -= Comic.edge_styles[shape.id].size() + 1 # +1 because the divider counts as an indexed item.
		shape = Comic.shapes.values()[index]
	else:
		edge_style = Comic.edge_styles[shape.id].values()[index]
	rebuild(true)

func _menu_preset_index_pressed(index:int, menu_preset:PopupMenu):
	if index == menu_preset.item_count - 1:
		# Manage Presets was selected
		Comic.book.open_presets_manager("balloon")
	else:
		# A preset was selected
		Comic.book.add_undo_step([ComicReversionData.new(self)])
		var key:String = Comic.book.presets.balloon.keys()[index + 1]
		if presets.has(key):
			presets.erase(key)
			menu_preset.set_item_checked(index, false)
		else:
			presets.push_back(key)
			menu_preset.set_item_checked(index, true)
		_scrub_redundant_data()
		rebuild(true)

func menu_layer_index_pressed(index:int):
	layer = Comic.LAYERS.size() - 1 - index
	rebuild(true)

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.ADD_TAIL:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			var new_tail:Dictionary = { "oid": Comic.book.page.make_oid() }
			tail_data[new_tail.oid] = new_tail
			rebuild(true)
			rebuild_widgets()
		ComicEditor.MenuCommand.DELETE:
			remove()
		ComicEditor.MenuCommand.CLEAR_FRAGMENT:
			Comic.book.page.remove_o_from_fragment(self)
		ComicEditor.MenuCommand.FRAGMENT_PROPERTIES:
			Comic.book.open_properties = Comic.book.fragment_properties
		ComicEditor.MenuCommand.OPEN_PROPERTIES:
			Comic.book.open_properties = Comic.book.balloon_properties
		ComicEditor.MenuCommand.RANDOMIZE:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			rng_seed = randi()
			rebuild(false)
		ComicEditor.MenuCommand.TOGGLE_COLLAPSE:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			collapse = !collapse
			rebuild(true)
		ComicEditor.MenuCommand.TOGGLE_WIDTH_CONTROL:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			if width > 0:
				width = 0
			else:
				_data.erase("width") # Reset to the default width
			Comic.book.page.redraw()
			rebuild_widgets()

func remove():
	# Create the undo step.
	# We add elements in the same order we perform them, because they're undone in reverse order.
	# So first we add the backlinked tails, then this balloon.
	var undo_reversions = []
	var connected_balloons:Array = []
	for oids in tail_backlinks:
		if not connected_balloons.has(oids.x):
			connected_balloons.push_back(oids.x)
	for oid in connected_balloons:
		undo_reversions.push_back(ComicReversionData.new(Comic.book.page.os[oid], false))
	undo_reversions.push_back(ComicReversionParent.new(self, get_parent()))
	Comic.book.add_undo_step(undo_reversions)
	delete()
	Comic.book.page.redraw(true)
	Comic.book.selected_element = null

func _scrub_redundant_data():
	# This method removes any data that matches the current default data.
	_default_data = Comic.get_preset_data("balloon", presets)
	for key in _default_data:
		if _data.has(key) and _data[key] == _default_data[key]:
			_data.erase(key)

func bump(direction:Vector2):
	#TODO: Figure out a way to not save on multiple bumps
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	anchor += direction * Comic.px_per_unit * ComicEditor.BUMP_AMOUNT
	for oids in tail_backlinks:
		Comic.book.page.os[oids.x].rebuild_tail(oids.y)
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

func get_save_data() -> Dictionary:
	return _data.duplicate()
