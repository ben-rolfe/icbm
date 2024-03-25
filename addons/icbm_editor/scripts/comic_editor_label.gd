class_name ComicEditorLabel
extends ComicLabel

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
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("properties.svg"))), "Label Properties", ComicEditor.MenuCommand.OPEN_PROPERTIES)
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
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Remove Label", ComicEditor.MenuCommand.DELETE)

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
	menu_layer.id_pressed.connect(menu.id_pressed.get_connections()[0].callable)
	menu_layer.name = "layer"
	if layer != Comic.book.page.layer_depth:
		menu_layer.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("pull_to_top.svg"))), "Pull to Front", ComicEditor.MenuCommand.PULL_TO_FRONT)
		if layer < Comic.book.page.layer_depth - 1:
			menu_layer.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("pull.svg"))), "Pull", ComicEditor.MenuCommand.PULL)
	menu_layer.add_separator(str("At Front  (+", Comic.book.page.layer_depth, ")") if layer == Comic.book.page.layer_depth else str("At Back (-", Comic.book.page.layer_depth, ")") if layer == -Comic.book.page.layer_depth else str("On layer ", "+" if layer > 0 else "", layer))
	if layer != -Comic.book.page.layer_depth:
		if layer > 1 - Comic.book.page.layer_depth:
			menu_layer.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("push.svg"))), "Push", ComicEditor.MenuCommand.PUSH)
		menu_layer.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("push_to_bottom.svg"))), "Push to Back", ComicEditor.MenuCommand.PUSH_TO_BACK)

	# Preset Submenu
	var menu_preset:PopupMenu = PopupMenu.new()
	menu.add_child(menu_preset)
	menu_preset.hide_on_checkable_item_selection = false
	menu_preset.index_pressed.connect(menu_preset_index_pressed.bind(menu_preset))
	menu_preset.name = "preset"
	for key in Comic.label_presets:
		menu_preset.add_check_item(Comic.label_presets[key].editor_name)
		menu_preset.set_item_checked(-1, presets.has(key))

func menu_preset_index_pressed(index:int, menu_preset:PopupMenu):
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	var key:String = Comic.label_presets.keys()[index]
	if presets.has(key):
		presets.erase(key)
		menu_preset.set_item_checked(index, false)
	else:
		presets.push_back(key)
		menu_preset.set_item_checked(index, true)
#	scrub_redundant_data()
	rebuild()

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
			Comic.book.open_properties = Comic.book.label_properties
		ComicEditor.MenuCommand.PULL:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			layer = layer + 1
			rebuild()
		ComicEditor.MenuCommand.PULL_TO_FRONT:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			layer = Comic.book.page.layer_depth
			rebuild()
		ComicEditor.MenuCommand.PUSH:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			layer = layer - 1
			rebuild()
		ComicEditor.MenuCommand.PUSH_TO_BACK:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			layer = -Comic.book.page.layer_depth
			rebuild()
		ComicEditor.MenuCommand.RANDOMIZE:
			Comic.book.add_undo_step([ComicReversionData.new(self)])
			rng_seed = randi()
			rebuild()
			
func rebuild_widgets():
	var draw_layer:ComicWidgetLayer = Comic.book.page.layers[-1]
	draw_layer.clear()
	draw_layer.add_child(ComicLabelRotateWidget.new(self))
	var scale_widget:ComicLabelScaleWidget = ComicLabelScaleWidget.new(self)
	draw_layer.add_child(scale_widget)
	var bulge_widget:ComicLabelBulgeWidget = ComicLabelBulgeWidget.new(scale_widget)
	draw_layer.add_child(bulge_widget)
	draw_layer.add_child(ComicLabelGrowWidget.new(bulge_widget))
	var curve_height_widget:ComicLabelCurveHeightWidget = ComicLabelCurveHeightWidget.new(self)
	draw_layer.add_child(curve_height_widget)
	draw_layer.add_child(ComicLabelCurvePeriodWidget.new(curve_height_widget))
	draw_layer.add_child(ComicLabelSpacingWidget.new(self))

func remove():
	Comic.book.add_undo_step([ComicReversionParent.new(self, get_parent())])
	get_parent().remove_child(self)
	Comic.book.page.redraw(true)
	Comic.book.selected_element = null
