class_name ComicEditorBalloonProperties
extends ComicEditorProperties

@export var text_edit:TextEdit
var balloon:ComicEditorBalloon
var text_before_changes:String

func _ready():
	text_edit.text_changed.connect(_on_text_changed)
	text_edit.caret_blink = true
	text_edit.focus_entered.connect(_on_text_focused)
	text_edit.focus_exited.connect(_on_text_unfocused)

func prepare():
	super()
	balloon = Comic.book.selected_element
	text_edit.text = ComicEditor.parse_text_edit(balloon.data.text)
	text_edit.grab_focus()
	if text_edit.text == ComicBalloon.DEFAULT_TEXT:
		text_edit.select_all()
	else:
		#TODO: There's gotta be a less weird way?!
		var text_end = text_edit.get_line_column_at_pos(size, true)
		text_edit.set_caret_line(text_end.y)
		text_edit.set_caret_column(text_end.x)

func _on_text_changed():
	balloon.data.text = ComicEditor.unparse_text_edit(text_edit.text)
	balloon.rebuild(true)

func _on_text_focused():
	text_before_changes = text_edit.text
	
func _on_text_unfocused():
	if text_edit.text != text_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(balloon)
		reversion.data.text = ComicEditor.unparse_text_edit(text_before_changes)
		Comic.book.add_undo_step([reversion])
