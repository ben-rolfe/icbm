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
	apply_data()
	Comic.book.page.redraw()

func after_reversion():
	rebuild()

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("properties.svg"))), "Kaboom Properties", ComicEditor.MenuCommand.OPEN_PROPERTIES)
	menu.add_separator()
	menu.add_submenu_item("Presets", "preset")
	menu.add_submenu_item("Align", "align")
	menu.add_separator()
	menu.add_submenu_item("Layer", "layer")
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("dice_", randi_range(1, 6), ".svg"))), "Rerandomize Effects", ComicEditor.MenuCommand.RANDOMIZE)
	#if not edge_style.is_randomized:
		#menu.set_item_disabled(-1, true)
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Remove Kaboom", ComicEditor.MenuCommand.DELETE)

	# Align Submenu
	var menu_anchor:PopupMenu = PopupMenu.new()
	menu.add_child(menu_anchor)
	menu_anchor.id_pressed.connect(menu.id_pressed.get_connections()[0].callable)
	menu_anchor.name = "align"
	menu_anchor.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("anchor_l.svg"))), "Left", ComicEditor.MenuCommand.ANCHOR_L)
	menu_anchor.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("anchor_c.svg"))), "Center", ComicEditor.MenuCommand.ANCHOR_C)
	menu_anchor.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("anchor_r.svg"))), "Right", ComicEditor.MenuCommand.ANCHOR_R)

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
