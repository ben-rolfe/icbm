class_name ComicEditorPresetsManager
extends Window

var category:String
var container:ScrollContainer
var list:VBoxContainer

func _init(_category:String):
	category = _category
	close_requested.connect(queue_free)
	transient = true
	exclusive = true
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	container = ScrollContainer.new()
	add_child(container)
	list = VBoxContainer.new()
	list.resized.connect(_on_list_resized)
	container.add_child(list)
	create_list()

func create_list():
	title = str(category.capitalize(), " Presets")
	for child in list.get_children():
		child.queue_free()
	for i in Comic.book.presets[category].size():
		var row:HBoxContainer = HBoxContainer.new()
		list.add_child(row)
		var delete_button:Button = Button.new()
		row.add_child(delete_button)
		delete_button.icon = load(str(ComicEditor.DIR_ICONS, "delete.svg"))
		delete_button.modulate = Color.RED
		var label = Label.new()
		row.add_child(label)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = Comic.book.presets[category].keys()[i].capitalize()
		if i > 0:
			var up_button:Button = Button.new()
			row.add_child(up_button)
			up_button.icon = load(str(ComicEditor.DIR_ICONS, "arrow_u.svg"))
			up_button.pressed.connect(_on_reorder_pressed.bind(i, i-1))
		else:
			var spacer = Button.new()
			row.add_child(spacer)
			spacer.icon = load(str(ComicEditor.DIR_ICONS, "blank.svg"))
			spacer.flat = true
			spacer.disabled = true
		if i < Comic.book.presets[category].size() -1:
			var down_button:Button = Button.new()
			row.add_child(down_button)
			down_button.icon = load(str(ComicEditor.DIR_ICONS, "arrow_d.svg"))
			down_button.pressed.connect(_on_reorder_pressed.bind(i, i+1))
		else:
			var spacer = Button.new()
			row.add_child(spacer)
			spacer.icon = load(str(ComicEditor.DIR_ICONS, "blank.svg"))
			spacer.flat = true
			spacer.disabled = true
		var edit_button:Button = Button.new()
		row.add_child(edit_button)
		edit_button.icon = load(str(ComicEditor.DIR_ICONS, "properties.svg"))
		edit_button.pressed.connect(create_properties.bind(Comic.book.presets[category].keys()[i]))
			
	var add_row:HBoxContainer = HBoxContainer.new()
	list.add_child(add_row)
	var add_button:Button = Button.new()
	add_row.add_child(add_button)
	add_button.icon = load(str(ComicEditor.DIR_ICONS, "add.svg"))
	add_button.pressed.connect(create_properties)
	var label = Label.new()
	add_row.add_child(label)
	label.text = "Add New Preset"

func create_properties(preset:String = ""):
	for child in list.get_children():
		child.queue_free()
	var name_row:HBoxContainer = HBoxContainer.new()
	list.add_child(name_row)
	var name_label:Label = Label.new()
	name_row.add_child(name_label)
	name_label.text = "Name:"
	var preset_name:LineEdit = LineEdit.new()
	name_row.add_child(preset_name)
	preset_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_name.text = preset.capitalize()

	var add_row:HBoxContainer = HBoxContainer.new()
	list.add_child(add_row)
	var add_button:Button = Button.new()
	add_row.add_child(add_button)
	add_button.icon = load(str(ComicEditor.DIR_ICONS, "add.svg"))
	add_button.pressed.connect(_on_new_property_pressed)
	var label = Label.new()
	add_row.add_child(label)
	label.text = "Add New Property"

	var buttons_row:HBoxContainer = HBoxContainer.new()
	list.add_child(buttons_row)
	var cancel_button:Button = Button.new()
	buttons_row.add_child(cancel_button)
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(create_list)
	var spacer:Control = Control.new()
	buttons_row.add_child(spacer)
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var save_button:Button = Button.new()
	buttons_row.add_child(save_button)
	save_button.text = "Save"
	save_button.pressed.connect(_on_save_pressed)

	if preset != "":
		preset_name.editable = false
		name_row.hide()
		title = str(preset.capitalize(), " Preset")
		for property in Comic.book.presets[category][preset]:
			if property in Comic.preset_properties[category]:
				_add_property_row(property, preset)
			else:
				printerr("Property '", property, "' exists in preset ", category, ">", preset, " but is absent from Comic.preset_properties.", category)

func _add_property_row(property:String, preset:String = ""):
	var row:HBoxContainer = HBoxContainer.new()
	list.get_child(-3).add_sibling(row)
	var delete_button:Button = Button.new()
	row.add_child(delete_button)
	delete_button.icon = load(str(ComicEditor.DIR_ICONS, "delete.svg"))
	delete_button.modulate = Color.RED
	delete_button.pressed.connect(row.queue_free)
	var label = Label.new()
	row.add_child(label)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = property.capitalize()
	match Comic.preset_properties[category][property]:
		"bool":
			var check_box:CheckBox = CheckBox.new()
			row.add_child(check_box)
			check_box.button_pressed = preset != "" and Comic.book.presets[category][preset][property]
		"color":
			var color_button:ColorPickerButton = ColorPickerButton.new()
			row.add_child(color_button)
			color_button.custom_minimum_size.x = 24
			if preset != "":
				color_button.color = Comic.book.presets[category][preset][property]
		"font":
			var option_button:OptionButton = OptionButton.new()
			row.add_child(option_button)
			for file_name in DirAccess.get_files_at(str(Comic.DIR_FONTS, category)):
				option_button.add_item(file_name.get_basename().capitalize())
				option_button.set_item_metadata(option_button.item_count - 1, file_name.get_basename())
				if preset != "" and Comic.book.presets[category][preset][property] == file_name.get_basename():
					option_button.select(option_button.item_count - 1)
		"int":
			var spin_box:SpinBox = SpinBox.new()
			spin_box.max_value = 999999
			spin_box.min_value = -999999
			row.add_child(spin_box)
			if preset != "":
				spin_box.value = Comic.book.presets[category][preset][property]
		"percent":
			var spin_box:SpinBox = SpinBox.new()
			row.add_child(spin_box)
			spin_box.max_value = 999999
			spin_box.min_value = -999999
			label.text = str(label.text, " (%)")
			if preset != "":
				spin_box.value = Comic.book.presets[category][preset][property] * 100
		"degrees":
			var spin_box:SpinBox = SpinBox.new()
			row.add_child(spin_box)
			spin_box.max_value = 999999
			spin_box.min_value = -999999
			label.text = str(label.text, " (°)")
			if preset != "":
				spin_box.value = Comic.book.presets[category][preset][property] * 360 / TAU
		_:
			if Comic.preset_properties[category][property] is Dictionary:
				var option_button:OptionButton = OptionButton.new()
				row.add_child(option_button)
				for option in Comic.preset_properties[category][property]:
					option_button.add_item(option)
					option_button.set_item_metadata(option_button.item_count - 1, Comic.preset_properties[category][property][option])
					if preset != "" and Comic.book.presets[category][preset][property] == Comic.preset_properties[category][property][option]:
						option_button.select(option_button.item_count - 1)
			elif Comic.preset_properties[category][property] is String and str(Comic.preset_properties[category][property], "s") in Comic and Comic[str(Comic.preset_properties[category][property], "s")] is Dictionary:
				# This is pretty hacky, I admit. I'm trying to make it extensible for modules.
				# If the property is an unrecognised string, and Comic[propertys] (i.e. the property with an s on the end) is a dictionary, then the value can be selected from a dropdown of the keys - the saved value is the key
				var option_button:OptionButton = OptionButton.new()
				row.add_child(option_button)
				for option in Comic[str(Comic.preset_properties[category][property], "s")]:
					option_button.add_item(option.capitalize())
					option_button.set_item_metadata(option_button.item_count - 1, option)
					if preset != "" and Comic.book.presets[category][preset][property] == option:
						option_button.select(option_button.item_count - 1)

func _on_save_pressed():
	var preset:String = Comic.validate_name(list.get_child(0).get_child(1).text)
	list.get_child(0).get_child(1).text = preset.capitalize()
	if preset == "":
		Comic.alert("Invalid Preset Name", "Preset name must begin with a letter and contain only letters, numbers, and spaces.")
	else:
		var dict:Dictionary = {}
		for i in range(1, list.get_child_count() - 2):
			var row:HBoxContainer = list.get_child(i)
			var property:String = Comic.validate_name(row.get_child(1).text)
			match Comic.preset_properties[category][property]:
				"bool":
					var check_box:CheckBox = row.get_child(2)
					dict[property] = check_box.button_pressed
				"color":
					var color_button:ColorPickerButton = row.get_child(2)
					dict[property] = color_button.color
				"int":
					var spin_box:SpinBox = row.get_child(2)
					dict[property] = spin_box.value
				"percent":
					var spin_box:SpinBox = row.get_child(2)
					dict[property] = spin_box.value / 100.0
				"degrees":
					var spin_box:SpinBox = row.get_child(2)
					dict[property] = spin_box.value * TAU / 360.0
				_:
					var option_button:OptionButton = row.get_child(2)
					dict[property] = option_button.get_selected_metadata()
		Comic.book.presets[category][preset] = dict
		_save_presets()
	
func _on_new_property_pressed():
	var current_properties:Array[String] = []
	for i in range(1, list.get_child_count() - 2):
		current_properties.push_back(Comic.validate_name(list.get_child(i).get_child(1).text))
	var menu = PopupMenu.new()
	add_child(menu)
	menu.index_pressed.connect(_on_property_menu_item_pressed.bind(menu))
	for property in Comic.preset_properties[category]:
		if not current_properties.has(property) and not (Comic.preset_properties[category][property] is String and Comic.preset_properties[category][property] == "hidden"):
			menu.add_item(property.capitalize())
			menu.set_item_metadata(menu.item_count -1, property)
	menu.position = position + Vector2i(get_mouse_position())
	menu.popup()
	menu.visibility_changed.connect(menu.queue_free)

func _on_property_menu_item_pressed(idx:int, menu:PopupMenu):
	_add_property_row(menu.get_item_metadata(idx))

func _on_list_resized():
	container.size = Vector2(min(list.size.x, Comic.size.x - 80), min(list.size.y, Comic.size.y - 80))
	size = container.size
	popup_centered()
	
func _on_reorder_pressed(from:int, to:int):
	# I couldn't figure out a way to reorder dictionary items apart from rebuilding.
	# (editing the arrays returned by keys() and values() didn't change the dictionary)
	var new_dict:Dictionary = {}
	for i in Comic.book.presets[category].size():
		if i == from:
			new_dict[Comic.book.presets[category].keys()[to]] = Comic.book.presets[category].values()[to]
		elif i == to:
			new_dict[Comic.book.presets[category].keys()[from]] = Comic.book.presets[category].values()[from]
		else:
			new_dict[Comic.book.presets[category].keys()[i]] = Comic.book.presets[category].values()[i]
	Comic.book.presets[category] = new_dict
	_save_presets()

func _save_presets():
	Comic.book.save_presets_file()
	Comic.book.page.rebuild(true)
	create_list()

