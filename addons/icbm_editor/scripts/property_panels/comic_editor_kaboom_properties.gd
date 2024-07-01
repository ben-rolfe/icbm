class_name ComicEditorKaboomProperties
extends ComicEditorProperties

@export var line_edit:LineEdit
var kaboom:ComicEditorKaboom
var text_before_changes:String

@export var font_button:OptionButton

@export var font_color_button:ColorPickerButton
@export var font_color_revert_button:Button
var font_color_before_changes:Color

@export var outline_color_button:ColorPickerButton
@export var outline_color_revert_button:Button
var outline_color_before_changes:Color

@export var shown_check_box:CheckBox
@export var appear_spin_box:SpinBox
@export var appear_button:OptionButton
@export var disappear_spin_box:SpinBox
@export var disappear_button:OptionButton

func _ready():
	line_edit.text_changed.connect(_on_text_changed)
	line_edit.caret_blink = true
	line_edit.focus_entered.connect(_on_text_focused)
	line_edit.focus_exited.connect(_on_text_unfocused)

	for file_name in DirAccess.get_files_at(str(Comic.DIR_FONTS, "kaboom")):
		font_button.add_item(file_name.get_basename().capitalize())
		font_button.set_item_metadata(font_button.item_count - 1, file_name.get_basename())
	font_button.item_selected.connect(_on_font_button_item_selected)

	font_color_button.pressed.connect(_on_font_color_opened)
	font_color_button.color_changed.connect(_on_font_color_changed)
	font_color_button.popup_closed.connect(_on_font_color_closed)
	font_color_revert_button.pressed.connect(_on_font_color_revert)
	font_color_revert_button.modulate = Color.BLACK

	outline_color_button.pressed.connect(_on_outline_color_opened)
	outline_color_button.color_changed.connect(_on_outline_color_changed)
	outline_color_button.popup_closed.connect(_on_outline_color_closed)
	outline_color_revert_button.pressed.connect(_on_outline_color_revert)
	outline_color_revert_button.modulate = Color.BLACK

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
	kaboom = Comic.book.selected_element
	line_edit.text = ComicEditor.parse_text_edit(kaboom.content)
	line_edit.grab_focus()
	if line_edit.text == Comic.default_presets.kaboom[""].content:
		line_edit.select_all()
	else:
		line_edit.caret_column = line_edit.text.length()

	for i in font_button.item_count:
		if font_button.get_item_metadata(i) == kaboom.font:
			font_button.select(i)
			break

	font_color_button.color = kaboom.font_color
	_after_font_color_change()

	outline_color_button.color = kaboom.outline_color
	_after_outline_color_change()

	shown_check_box.button_pressed = kaboom.shown
	appear_spin_box.value = kaboom.appear
	appear_button.select(kaboom.appear_type)
	if kaboom.appear_type == 0:
		appear_spin_box.hide()
	else:
		appear_spin_box.show()
		
	disappear_spin_box.value = kaboom.disappear
	disappear_button.select(kaboom.disappear_type)
	if kaboom.disappear_type == 0:
		disappear_spin_box.hide()
	else:
		disappear_spin_box.show()


func _on_text_changed(new_text:String):
	kaboom.content = ComicEditor.unparse_text_edit(line_edit.text)
	kaboom.rebuild(true)

func _on_text_focused():
	text_before_changes = line_edit.text
	
func _on_text_unfocused():
	if line_edit.text != text_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(kaboom)
		reversion.data.text = ComicEditor.unparse_text_edit(text_before_changes)
		Comic.book.add_undo_step([reversion])

func _on_font_color_opened():
	font_color_before_changes = kaboom.font_color

func _on_font_color_changed(color:Color):
	kaboom.font_color = color
	_after_font_color_change()

func _on_font_color_closed():
	if kaboom.font_color != font_color_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(kaboom)
		reversion.data.font_color = font_color_before_changes
		Comic.book.add_undo_step([reversion])

func _on_font_color_revert():
	if kaboom.data.has("font_color"):
		Comic.book.add_undo_step([ComicReversionData.new(kaboom)])
		kaboom.data.erase("font_color")
		_after_font_color_change()
		font_color_button.color = kaboom.font_color

func _after_font_color_change():
	kaboom.rebuild(true)
	if kaboom.is_default("font_color"):
		font_color_revert_button.hide()
	else:
		font_color_revert_button.show()

func _on_outline_color_opened():
	outline_color_before_changes = kaboom.outline_color

func _on_outline_color_changed(color:Color):
	kaboom.outline_color = color
	_after_outline_color_change()

func _on_outline_color_closed():
	if kaboom.outline_color != outline_color_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(kaboom)
		reversion.data.outline_color = outline_color_before_changes
		Comic.book.add_undo_step([reversion])

func _on_outline_color_revert():
	if kaboom.data.has("outline_color"):
		Comic.book.add_undo_step([ComicReversionData.new(kaboom)])
		kaboom.data.erase("outline_color")
		_after_outline_color_change()
		outline_color_button.color = kaboom.outline_color

func _after_outline_color_change():
	kaboom.rebuild(true)
	if kaboom.is_default("outline_color"):
		outline_color_revert_button.hide()
	else:
		outline_color_revert_button.show()
		
func _on_shown_check_box_toggled(toggled_on:bool):
	Comic.book.add_undo_step([ComicReversionData.new(kaboom)])
	kaboom.shown = toggled_on

func _on_appear_button_item_selected(index:int):
	if index == 0:
		# We don't have an undo step here, because the next line will trigger one
		appear_spin_box.value = 0
		appear_spin_box.hide()
	else:
		Comic.book.add_undo_step([ComicReversionData.new(kaboom)])
		appear_spin_box.show()
	kaboom.appear_type = appear_button.get_item_metadata(index)

func _on_disappear_button_item_selected(index:int):
	if index == 0:
		# We don't have an undo step here, because the next line will trigger one
		disappear_spin_box.value = 0
		disappear_spin_box.hide()
	else:
		Comic.book.add_undo_step([ComicReversionData.new(kaboom)])
		disappear_spin_box.show()
	kaboom.disappear_type = disappear_button.get_item_metadata(index)
		
func _on_appear_spin_box_value_changed(value:int):
	Comic.book.add_undo_step([ComicReversionData.new(kaboom)])
	kaboom.appear = value

func _on_disappear_spin_box_value_changed(value:int):
	Comic.book.add_undo_step([ComicReversionData.new(kaboom)])
	kaboom.disappear = value
	
func _on_font_button_item_selected(index:int):
	Comic.book.add_undo_step([ComicReversionData.new(kaboom)])
	kaboom.font = font_button.get_item_metadata(index)
	kaboom.rebuild(true)
