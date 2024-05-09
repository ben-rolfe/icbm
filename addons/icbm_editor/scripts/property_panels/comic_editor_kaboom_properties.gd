class_name ComicEditorKaboomProperties
extends ComicEditorProperties

@export var line_edit:LineEdit
var kaboom:ComicEditorKaboom
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
	kaboom = Comic.book.selected_element
	line_edit.text = ComicEditor.parse_text_edit(kaboom.content)
	line_edit.grab_focus()
	if line_edit.text == Comic.default_presets.kaboom[""].content:
		line_edit.select_all()
	else:
		line_edit.caret_column = line_edit.text.length()

	font_color_button.color = kaboom.font_color
	_after_font_color_change()

	outline_color_button.color = kaboom.outline_color
	_after_outline_color_change()


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
