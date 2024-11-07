class_name ComicEditorLineEditProperties
extends ComicEditorProperties

@export var var_edit:LineEdit
@export var text_edit:LineEdit
@export var enabled_text_edit:TextEdit

var line_edit:ComicEditorLineEdit
var var_before_changes:String
var text_before_changes:String
var commands_before_changes:String
var enabled_before_changes:String

@export var shown_check_box:CheckBox
@export var appear_spin_box:SpinBox
@export var appear_button:OptionButton
@export var disappear_spin_box:SpinBox
@export var disappear_button:OptionButton

func _ready():
	var_edit.text_changed.connect(_on_var_changed)
	var_edit.caret_blink = true
	var_edit.focus_entered.connect(_on_var_focused)
	var_edit.focus_exited.connect(_on_var_unfocused)

	text_edit.text_changed.connect(_on_text_changed)
	text_edit.caret_blink = true
	text_edit.focus_entered.connect(_on_text_focused)
	text_edit.focus_exited.connect(_on_text_unfocused)

	enabled_text_edit.text_changed.connect(_on_enabled_text_edit_changed)
	enabled_text_edit.caret_blink = true
	enabled_text_edit.focus_entered.connect(_on_enabled_text_edit_focused)
	enabled_text_edit.focus_exited.connect(_on_enabled_text_edit_unfocused)

	shown_check_box.toggled.connect(_on_shown_check_box_toggled)
	for i in Comic.DELAY_TYPES.size():
		appear_button.add_item(Comic.DELAY_TYPES[i])
		appear_button.set_item_metadata(-1, i)
		disappear_button.add_item(Comic.DELAY_TYPES[i])
		disappear_button.set_item_metadata(-1, i)
	appear_button.item_selected.connect(_on_appear_button_item_selected)
	appear_spin_box.value_changed.connect(_on_appear_spin_box_value_changed)
	disappear_button.item_selected.connect(_on_disappear_button_item_selected)
	disappear_spin_box.value_changed.connect(_on_disappear_spin_box_value_changed)


func prepare():
	super()
	line_edit = Comic.book.selected_element

	var_edit.text = ComicEditor.parse_text_edit(line_edit.var_name)
	text_edit.text = ComicEditor.parse_text_edit(line_edit.default_text)
	text_edit.grab_focus()
	if text_edit.text == Comic.default_presets.button[""].content:
		text_edit.select_all()
	else:
		text_edit.caret_column = text_edit.text.length()

	enabled_text_edit.text = line_edit.enabled_test

	shown_check_box.button_pressed = line_edit.shown
	appear_spin_box.value = line_edit.appear
	appear_button.select(line_edit.appear_type)
	if line_edit.appear_type == 0:
		appear_spin_box.hide()
	else:
		appear_spin_box.show()
		
	disappear_spin_box.value = line_edit.disappear
	disappear_button.select(line_edit.disappear_type)
	if line_edit.disappear_type == 0:
		disappear_spin_box.hide()
	else:
		disappear_spin_box.show()

func _on_var_changed(new_text:String):
	line_edit.var_name = ComicEditor.unparse_text_edit(var_edit.text)
	line_edit.rebuild(true)

func _on_var_focused():
	var_before_changes = var_edit.text
	
func _on_var_unfocused():
	if var_edit.text != var_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(line_edit)
		reversion.data.var_name = ComicEditor.unparse_text_edit(var_before_changes)
		Comic.book.add_undo_step([reversion])

func _on_text_changed(new_text:String):
	line_edit.default_text = ComicEditor.unparse_text_edit(text_edit.text)
	line_edit.rebuild(true)

func _on_text_focused():
	text_before_changes = text_edit.text
	
func _on_text_unfocused():
	if text_edit.text != text_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(line_edit)
		reversion.data.default_text = ComicEditor.unparse_text_edit(text_before_changes)
		Comic.book.add_undo_step([reversion])

func _on_enabled_text_edit_changed():
	line_edit.enabled_test = ComicEditor.unparse_text_edit(enabled_text_edit.text)
	line_edit.rebuild(true)

func _on_enabled_text_edit_focused():
	enabled_before_changes = enabled_text_edit.text
	
func _on_enabled_text_edit_unfocused():
	if enabled_text_edit.text != enabled_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(line_edit)
		reversion.data.enabled_test = ComicEditor.unparse_text_edit(enabled_before_changes)
		Comic.book.add_undo_step([reversion])

func _on_shown_check_box_toggled(toggled_on:bool):
	Comic.book.add_undo_step([ComicReversionData.new(line_edit)])
	line_edit.shown = toggled_on

func _on_appear_button_item_selected(index:int):
	if index == 0:
		# We don't have an undo step here, because the next line will trigger one
		appear_spin_box.value = 0
		appear_spin_box.hide()
	else:
		Comic.book.add_undo_step([ComicReversionData.new(line_edit)])
		appear_spin_box.show()
	line_edit.appear_type = appear_button.get_item_metadata(index)

func _on_disappear_button_item_selected(index:int):
	if index == 0:
		# We don't have an undo step here, because the next line will trigger one
		disappear_spin_box.value = 0
		disappear_spin_box.hide()
	else:
		Comic.book.add_undo_step([ComicReversionData.new(line_edit)])
		disappear_spin_box.show()
	line_edit.disappear_type = disappear_button.get_item_metadata(index)
		
func _on_appear_spin_box_value_changed(value:int):
	Comic.book.add_undo_step([ComicReversionData.new(line_edit)])
	line_edit.appear = value

func _on_disappear_spin_box_value_changed(value:int):
	Comic.book.add_undo_step([ComicReversionData.new(line_edit)])
	line_edit.disappear = value
	
