class_name ComicEditorLabelProperties
extends ComicEditorProperties

@export var line_edit:LineEdit
var label:ComicEditorLabel
var text_before_changes:String

func _ready():
	line_edit.text_changed.connect(_on_text_changed)
	line_edit.caret_blink = true
	line_edit.focus_entered.connect(_on_text_focused)
	line_edit.focus_exited.connect(_on_text_unfocused)

func prepare():
	super()
	label = Comic.book.selected_element
	line_edit.text = ComicEditor.parse_text_edit(label.data.text)
	line_edit.grab_focus()
	if line_edit.text == ComicLabel.DEFAULT_TEXT:
		line_edit.select_all()
	else:
		line_edit.caret_column = line_edit.text.length()

func _on_text_changed(new_text:String):
	print("boop1")
	label.data.text = ComicEditor.unparse_text_edit(line_edit.text)
	label.rebuild(true)

func _on_text_focused():
	print("boop2")
	text_before_changes = line_edit.text
	
func _on_text_unfocused():
	print("boop3")
	if line_edit.text != text_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(label)
		reversion.data.text = ComicEditor.unparse_text_edit(text_before_changes)
		Comic.book.add_undo_step([reversion])
