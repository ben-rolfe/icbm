class_name ComicEditorKaboomProperties
extends ComicEditorProperties

@export var line_edit:LineEdit
var label:ComicEditorKaboom
var text_before_changes:String

@export var font_color_button:ColorPickerButton
@export var font_color_revert_button:Button
var font_color_before_changes:Color

@export var outline_color_button:ColorPickerButton
@export var outline_color_revert_button:Button
var outline_color_before_changes:Color

func _ready():
	line_edit.text_changed.connect(_on_text_changed)
	line_edit.caret_blink = true
	line_edit.focus_entered.connect(_on_text_focused)
	line_edit.focus_exited.connect(_on_text_unfocused)

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

func prepare():
	super()
	label = Comic.book.selected_element
	line_edit.text = ComicEditor.parse_text_edit(label.data.text)
	line_edit.grab_focus()
	if line_edit.text == ComicKaboom.DEFAULT_TEXT:
		line_edit.select_all()
	else:
		line_edit.caret_column = line_edit.text.length()

	font_color_button.color = label.font_color
	_after_font_color_change()

	outline_color_button.color = label.outline_color
	_after_outline_color_change()


func _on_text_changed(new_text:String):
	label.data.text = ComicEditor.unparse_text_edit(line_edit.text)
	label.rebuild(true)

func _on_text_focused():
	text_before_changes = line_edit.text
	
func _on_text_unfocused():
	if line_edit.text != text_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(label)
		reversion.data.text = ComicEditor.unparse_text_edit(text_before_changes)
		Comic.book.add_undo_step([reversion])

func _on_font_color_opened():
	font_color_before_changes = label.font_color

func _on_font_color_changed(color:Color):
	label.font_color = color
	_after_font_color_change()

func _on_font_color_closed():
	if label.font_color != font_color_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(label)
		reversion.data.font_color = font_color_before_changes
		Comic.book.add_undo_step([reversion])

func _on_font_color_revert():
	if label.data.has("font_color"):
		Comic.book.add_undo_step([ComicReversionData.new(label)])
		label.data.erase("font_color")
		_after_font_color_change()
		font_color_button.color = label.font_color

func _after_font_color_change():
	label.rebuild(true)
	if label.is_default("font_color"):
		font_color_revert_button.hide()
	else:
		font_color_revert_button.show()

func _on_outline_color_opened():
	outline_color_before_changes = label.outline_color

func _on_outline_color_changed(color:Color):
	label.outline_color = color
	_after_outline_color_change()

func _on_outline_color_closed():
	if label.outline_color != outline_color_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(label)
		reversion.data.outline_color = outline_color_before_changes
		Comic.book.add_undo_step([reversion])

func _on_outline_color_revert():
	if label.data.has("outline_color"):
		Comic.book.add_undo_step([ComicReversionData.new(label)])
		label.data.erase("outline_color")
		_after_outline_color_change()
		outline_color_button.color = label.outline_color

func _after_outline_color_change():
	label.rebuild(true)
	if label.is_default("outline_color"):
		outline_color_revert_button.hide()
	else:
		outline_color_revert_button.show()
