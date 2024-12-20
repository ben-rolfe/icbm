class_name ComicEditorKaboom
extends ComicKaboom

const WIDGET_COLOR:Color = Color.WHITE

func draw_widgets(layer:ComicWidgetLayer):
	# Draw a cross-hairs at the anchor
	layer.draw_line(anchor + Vector2.UP * ComicWidget.RADIUS, anchor + Vector2.DOWN * ComicWidget.RADIUS, WIDGET_COLOR, ComicWidget.THICK)
	layer.draw_line(anchor + Vector2.LEFT * ComicWidget.RADIUS, anchor + Vector2.RIGHT * ComicWidget.RADIUS, WIDGET_COLOR, ComicWidget.THICK)

	for child in get_children():
		# Draw a cross-hairs at the child's position
		#layer.draw_line(position + child.position + Vector2.UP * ComicWidget.RADIUS, position + child.position + Vector2.DOWN * ComicWidget.RADIUS, Color.WHITE, ComicWidget.THIN)
		#layer.draw_line(position + child.position + Vector2.LEFT * ComicWidget.RADIUS, position + child.position + Vector2.RIGHT * ComicWidget.RADIUS, Color.WHITE, ComicWidget.THIN)

		# Draw a box around the char
		var shifted_bounds = child.bounds.duplicate()
		for i in shifted_bounds.size():
			shifted_bounds[i] += child.position - pivot_offset
			shifted_bounds[i] = shifted_bounds[i].rotated(rotation)
			shifted_bounds[i] += position + pivot_offset
		layer.draw_polyline(shifted_bounds, WIDGET_COLOR)


func has_point(point:Vector2) -> bool:
	for child in get_children():
		var shifted_bounds = child.bounds.duplicate()
		#TODO: Precalculate shifted bounds for efficiency.
		for i in shifted_bounds.size():
			shifted_bounds[i] += child.position - pivot_offset
			shifted_bounds[i] = shifted_bounds[i].rotated(rotation)
			shifted_bounds[i] += position + pivot_offset
		if Geometry2D.is_point_in_polygon(point, shifted_bounds):
			return true
	return false

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	Comic.book.grab(self, at_position - anchor)

func dropped(global_position:Vector2):
	dragged(global_position)
	
func dragged(global_position:Vector2):
	anchor = ComicEditor.snap(global_position)
	rebuild()

func rebuild(_rebuild_subobjects:bool = false):
	super()
	Comic.book.page.redraw()

func after_reversion():
	rebuild()

func add_menu_items(menu:PopupMenu):
	# Align Submenu
	var menu_anchor:PopupMenu = PopupMenu.new()
	menu.add_child(menu_anchor)
	menu_anchor.id_pressed.connect(menu.id_pressed.get_connections()[0].callable)
	menu_anchor.name = "align"
	menu_anchor.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("anchor_l.svg"))), "Left", ComicEditor.MenuCommand.ANCHOR_L)
	menu_anchor.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("anchor_c.svg"))), "Center", ComicEditor.MenuCommand.ANCHOR_C)
	menu_anchor.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("anchor_r.svg"))), "Right", ComicEditor.MenuCommand.ANCHOR_R)

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

	# Layer Submenu
	var menu_layer:PopupMenu = PopupMenu.new()
	menu.add_child(menu_layer)
	menu_layer.id_pressed.connect(menu_layer_index_pressed)
	menu_layer.name = "layer"
	for i in range(Comic.LAYERS.size() - 1, -1, -1):
		menu_layer.add_icon_item(load(str(ComicEditor.DIR_ICONS, "checked.svg" if i == layer else "unchecked.svg")), Comic.LAYERS[i])

	# Preset Submenu
	var menu_preset:PopupMenu = PopupMenu.new()
	menu.add_child(menu_preset)
	menu_preset.hide_on_checkable_item_selection = false
	menu_preset.index_pressed.connect(menu_preset_index_pressed.bind(menu_preset))
	menu_preset.name = "preset"
	for key in Comic.book.presets.kaboom:
		if key != "":
			menu_preset.add_check_item(key.capitalize())
			menu_preset.set_item_checked(-1, presets.has(key))
	menu_preset.add_separator()
	menu_preset.add_item("Manage Presets / Defaults")
	
	# Main Kaboom Menu
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("properties.svg"))), "Kaboom Properties", ComicEditor.MenuCommand.OPEN_PROPERTIES)
	menu.add_separator()
	menu.add_submenu_item("Presets", "preset")
	menu.add_submenu_item("Align", "align")
	#menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("dice_", randi_range(1, 6), ".svg"))), "Rerandomize Effects", ComicEditor.MenuCommand.RANDOMIZE)
	#if not edge_style.is_randomized:
		#menu.set_item_disabled(-1, true)
	menu.add_separator()
	menu.add_submenu_item("Layer", "layer")
	menu.add_separator()
	if fragment != "":
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("fragment.svg"))), str(fragment.capitalize(), " Properties"), ComicEditor.MenuCommand.FRAGMENT_PROPERTIES)
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("clear_fragment.svg"))), str("Remove from ", fragment.capitalize()), ComicEditor.MenuCommand.CLEAR_FRAGMENT)
	else:
		menu.add_submenu_item("Add to Fragment", "fragment")
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Remove Kaboom", ComicEditor.MenuCommand.DELETE)



func menu_preset_index_pressed(index:int, menu_preset:PopupMenu):
	if index == menu_preset.item_count - 1:
		# Manage Presets was selected
		Comic.book.open_presets_manager("kaboom")
	else:
		Comic.book.add_undo_step([ComicReversionData.new(self)])
		var key:String = Comic.book.presets.kaboom.keys()[index + 1]
		if presets.has(key):
			presets.erase(key)
			menu_preset.set_item_checked(index, false)
		else:
			presets.push_back(key)
			menu_preset.set_item_checked(index, true)
	#	scrub_redundant_data()
		rebuild()

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
		ComicEditor.MenuCommand.ANCHOR_L:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			align = HORIZONTAL_ALIGNMENT_LEFT
			rebuild()
			rebuild_widgets()
		ComicEditor.MenuCommand.ANCHOR_C:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			align = HORIZONTAL_ALIGNMENT_CENTER
			rebuild()
			rebuild_widgets()
		ComicEditor.MenuCommand.ANCHOR_R:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			align = HORIZONTAL_ALIGNMENT_RIGHT
			rebuild()
			rebuild_widgets()
		ComicEditor.MenuCommand.CLEAR_FRAGMENT:
			Comic.book.page.remove_o_from_fragment(self)
		ComicEditor.MenuCommand.FRAGMENT_PROPERTIES:
			Comic.book.open_properties = Comic.book.fragment_properties
		ComicEditor.MenuCommand.DELETE:
			remove()
		ComicEditor.MenuCommand.OPEN_PROPERTIES:
			Comic.book.open_properties = Comic.book.kaboom_properties
		ComicEditor.MenuCommand.RANDOMIZE:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			rng_seed = randi()
			rebuild()
			
func rebuild_widgets():
	var draw_layer:ComicWidgetLayer = Comic.book.page.layers[-1]
	draw_layer.clear()
	draw_layer.add_child(ComicKaboomRotateWidget.new(self))
	var scale_widget:ComicKaboomScaleWidget = ComicKaboomScaleWidget.new(self)
	draw_layer.add_child(scale_widget)
	var bulge_widget:ComicKaboomBulgeWidget = ComicKaboomBulgeWidget.new(scale_widget)
	draw_layer.add_child(bulge_widget)
	draw_layer.add_child(ComicKaboomGrowWidget.new(bulge_widget))
	var wave_height_widget:ComicKaboomWaveHeightWidget = ComicKaboomWaveHeightWidget.new(self)
	draw_layer.add_child(wave_height_widget)
	draw_layer.add_child(ComicKaboomWavePeriodWidget.new(wave_height_widget))
	draw_layer.add_child(ComicKaboomSpacingWidget.new(self))

func remove():
	Comic.book.add_undo_step([ComicReversionParent.new(self, get_parent())])
	get_parent().remove_child(self)
	Comic.book.page.redraw(true)
	Comic.book.selected_element = null

func get_save_data() -> Dictionary:
	return _data.duplicate()

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
