class_name ComicEditorLineEdit
extends ComicLineEdit

func _init(data:Dictionary, page:ComicPage):
	super(data, page)
	editable = false

func apply_data():
	super()
	editable = false

func _gui_input(event):
	#NOTE: We don't call super() - we don't want to activate the player events (if any)
	if enabled and event is InputEventMouseButton and hovered:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_double_click():
			Comic.book.selected_element = self
			Comic.book.open_properties = Comic.book.line_edit_properties
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.is_pressed():
			Comic.book.selected_element = self
			Comic.book.open_menu(self, get_viewport().get_mouse_position())

func _on_text_changed(s:String):
	# We override this method, because we don't want to set the variable that this line_edit is attached to, when in edit mode
	pass

func rebuild(_rebuild_subobjects:bool = false):
	apply_data()

func after_reversion():
	rebuild()

func add_menu_items(menu:PopupMenu):
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
	for key in Comic.book.presets.line_edit:
		if key != "":
			menu_preset.add_check_item(key.capitalize())
			menu_preset.set_item_checked(-1, presets.has(key))
	menu_preset.add_separator()
	menu_preset.add_item("Manage Presets / Defaults")
	
	# Main TextEdit Menu
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("properties.svg"))), "Text Entry Properties", ComicEditor.MenuCommand.OPEN_PROPERTIES)
	menu.add_separator()
	menu.add_submenu_item("Presets", "preset")
	menu.add_separator()
	if fragment != "":
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("fragment.svg"))), str(fragment.capitalize(), " Properties"), ComicEditor.MenuCommand.FRAGMENT_PROPERTIES)
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("clear_fragment.svg"))), str("Remove from ", fragment.capitalize()), ComicEditor.MenuCommand.CLEAR_FRAGMENT)
	else:
		menu.add_submenu_item("Add to Fragment", "fragment")
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Remove Text Entry", ComicEditor.MenuCommand.DELETE)

func menu_fragment_index_pressed(index:int):
	if index < Comic.book.page.fragments.keys().size():
		fragment = Comic.book.page.fragments.keys()[index]
	else:
		# Add new fragment pressed
		Comic.book.page.new_fragment(ComicEditor.get_unique_array_item(Comic.book.page.fragments.keys(), "fragment_1"), self)
	Comic.book.open_properties = Comic.book.fragment_properties

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DELETE:
			remove()
		ComicEditor.MenuCommand.OPEN_PROPERTIES:
			Comic.book.open_properties = Comic.book.line_edit_properties
		ComicEditor.MenuCommand.CLEAR_FRAGMENT:
			Comic.book.page.remove_o_from_fragment(self)
		ComicEditor.MenuCommand.FRAGMENT_PROPERTIES:
			Comic.book.open_properties = Comic.book.fragment_properties

func _menu_preset_index_pressed(index:int, menu_preset:PopupMenu):
	if index == menu_preset.item_count - 1:
		# Manage Presets was selected
		Comic.book.open_presets_manager("text_edit")
	else:
		# A preset was selected
		Comic.book.add_undo_step([ComicReversionData.new(self)])
		var key:String = Comic.book.presets.button.keys()[index + 1]
		print(presets)
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

func rebuild_widgets():
	var draw_layer:ComicWidgetLayer = Comic.book.page.layers[-1]
	draw_layer.clear()
	draw_layer.add_child(ComicMoveWidget.new(self))
	draw_layer.add_child(ComicWidthWidget.new(self))

func remove():
	# Create the undo step.
	Comic.book.add_undo_step([ComicReversionParent.new(self, get_parent())])
	# We don't free it now - it survives in the undo queue - it will be freed when its undo step is removed from the queue
	get_parent().remove_child(self)
	Comic.book.page.redraw(true)
	Comic.book.selected_element = null

func get_save_data() -> Dictionary:
	var r:Dictionary = _data.duplicate()
	r.order = get_index()
	return r
