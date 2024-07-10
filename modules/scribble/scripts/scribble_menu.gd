class_name ScribbleMenu
extends Window

const MARGIN:int = 24

var buttons:VBoxContainer
var tool_button:OptionButton = OptionButton.new()
var size_spinbox:SpinBox = SpinBox.new()
var color_button:ColorPickerButton = ColorPickerButton.new()
var editor_only_checkbox:CheckBox = CheckBox.new()

func _init():
	title = "Scribble"
	close_requested.connect(Scribble.close)
	

func _ready():
	buttons = VBoxContainer.new()
	add_child(buttons)
	buttons.resized.connect(_on_buttons_resized)

	buttons.add_child(tool_button)
	tool_button.item_selected.connect(_on_tool_selected)
	for tool in ScribbleRect.Tool:
		tool_button.add_icon_item(load(str("res://modules/scribble/icons/", tool, ".svg").to_lower()), str(tool).capitalize())

	var size_row:HBoxContainer = HBoxContainer.new()
	buttons.add_child(size_row)
	var size_label:Label = Label.new()
	size_row.add_child(size_label)
	size_label.text = "Size"
	size_row.add_child(size_spinbox)
	size_spinbox.min_value = 1
	size_spinbox.max_value = 100
	size_spinbox.value = Scribble.scribble_rect.eraser_size if Scribble.scribble_rect.tool == ScribbleRect.Tool.ERASER else Scribble.scribble_rect.pencil_size
	size_spinbox.update_on_text_changed = true
	size_spinbox.value_changed.connect(_on_size_changed)

	buttons.add_child(color_button)
	color_button.text = " "
	color_button.edit_alpha = false
	color_button.color_changed.connect(_on_color_changed)

	buttons.add_child(editor_only_checkbox)
	editor_only_checkbox.text = "Only Show in Editor"
	editor_only_checkbox.toggled.connect(_editor_only_toggled)
	
	var clear_button:Button = Button.new()
	buttons.add_child(clear_button)
	clear_button.text = "Clear Scribble"
	clear_button.pressed.connect(_on_clear_pressed)

func _input(event:InputEvent):
	if event is InputEventKey and event.pressed:
		# Pass keypresses to the scribble_rect for processing
		Scribble.scribble_rect._input(event)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		# On a right click, we close the scribble and manually pass the click event to the background.
		Scribble.close()
		Comic.book.page.background._gui_input(event)

func _on_color_changed(new_color:Color):
	Scribble.scribble_rect.pencil_color = new_color

func _on_tool_selected(index:int):
	Scribble.scribble_rect.tool = index as ScribbleRect.Tool
	match index:
		ScribbleRect.Tool.ERASER:
			size_spinbox.value = Scribble.scribble_rect.eraser_size
			color_button.hide()
		_:
			size_spinbox.value = Scribble.scribble_rect.pencil_size
			color_button.color = Scribble.scribble_rect.pencil_color
			color_button.show()

func _on_size_changed(value:int):
	if Scribble.scribble_rect.tool == ScribbleRect.Tool.ERASER:
		Scribble.scribble_rect.eraser_size = value
	else:
		Scribble.scribble_rect.pencil_size = value

func _editor_only_toggled(value:bool):
	Scribble.editor_only = value
	Scribble.needs_save = true
	
func _on_buttons_resized():
	size = Vector2(min(buttons.size.x, Comic.size.x - 80), min(buttons.size.y, Comic.size.y - 80))
	_fit_in_screen()

func _fit_in_screen():
	if position.x + size.x / 2.0 > Comic.size.x - MARGIN:
		position.x = int(Comic.size.x - size.x / 2.0 - MARGIN)
	if position.x - size.x / 2.0 < MARGIN:
		position.x = MARGIN
	if position.y + size.y / 2.0 > Comic.size.y - MARGIN:
		position.y = int(Comic.size.y - size.y / 2.0 - MARGIN)
	if position.y - size.y / 2.0 < MARGIN * 2:
		position.y = MARGIN * 2

func open():
	popup()
	_fit_in_screen()

	tool_button.select(Scribble.scribble_rect.tool)
	_on_tool_selected(Scribble.scribble_rect.tool)

	editor_only_checkbox.button_pressed = Scribble.editor_only

func _on_clear_pressed():
	Scribble.scribble_rect.create_undo_step()
	Scribble.scribble_rect.clear_image()
