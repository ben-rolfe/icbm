class_name ComicEditorBalloonProperties
extends ComicEditorProperties

@export var text_edit:TextEdit
var balloon:ComicEditorBalloon
var text_before_changes:String

@export var edge_color_button:ColorPickerButton
@export var edge_color_revert_button:Button
var edge_color_before_changes:Color

@export var fill_color_button:ColorPickerButton
@export var fill_color_revert_button:Button
var fill_color_before_changes:Color

@export var font_color_button:ColorPickerButton
@export var font_color_revert_button:Button
var font_color_before_changes:Color

func _ready():
	text_edit.text_changed.connect(_on_text_changed)
	text_edit.caret_blink = true
	text_edit.focus_entered.connect(_on_text_focused)
	text_edit.focus_exited.connect(_on_text_unfocused)

	edge_color_button.pressed.connect(_on_edge_color_opened)
	edge_color_button.color_changed.connect(_on_edge_color_changed)
	edge_color_button.popup_closed.connect(_on_edge_color_closed)
	edge_color_revert_button.pressed.connect(_on_edge_color_revert)
	edge_color_revert_button.modulate = Color.BLACK
	
	fill_color_button.pressed.connect(_on_fill_color_opened)
	fill_color_button.color_changed.connect(_on_fill_color_changed)
	fill_color_button.popup_closed.connect(_on_fill_color_closed)
	fill_color_revert_button.pressed.connect(_on_fill_color_revert)
	fill_color_revert_button.modulate = Color.BLACK

	font_color_button.pressed.connect(_on_font_color_opened)
	font_color_button.color_changed.connect(_on_font_color_changed)
	font_color_button.popup_closed.connect(_on_font_color_closed)
	font_color_revert_button.pressed.connect(_on_font_color_revert)
	font_color_revert_button.modulate = Color.BLACK

func prepare():
	super()
	balloon = Comic.book.selected_element
	text_edit.text = ComicEditor.parse_text_edit(balloon.data.text)
	text_edit.grab_focus()
	if text_edit.text == balloon._default_data.text:
		text_edit.select_all()
	else:
		#TODO: There's gotta be a less weird way?!
		var text_end = text_edit.get_line_column_at_pos(size, true)
		text_edit.set_caret_line(text_end.y)
		text_edit.set_caret_column(text_end.x)

	edge_color_button.color = balloon.edge_color
	_after_edge_color_change()

	fill_color_button.color = balloon.fill_color
	_after_fill_color_change()

	font_color_button.color = balloon.font_color
	_after_font_color_change()

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

func _on_edge_color_opened():
	edge_color_before_changes = balloon.edge_color

func _on_edge_color_changed(color:Color):
	balloon.edge_color = color
	_after_edge_color_change()

func _on_edge_color_closed():
	if balloon.edge_color != edge_color_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(balloon)
		reversion.data.edge_color = edge_color_before_changes
		Comic.book.add_undo_step([reversion])

func _on_edge_color_revert():
	if balloon.data.has("edge_color"):
		Comic.book.add_undo_step([ComicReversionData.new(balloon)])
		balloon.data.erase("edge_color")
		_after_edge_color_change()
		edge_color_button.color = balloon.edge_color

func _after_edge_color_change():
	balloon.rebuild(true)
	if balloon.is_default("edge_color"):
		edge_color_revert_button.hide()
	else:
		edge_color_revert_button.show()
		
func _on_fill_color_opened():
	fill_color_before_changes = balloon.fill_color

func _on_fill_color_changed(color:Color):
	balloon.fill_color = color
	_after_fill_color_change()

func _on_fill_color_closed():
	if balloon.fill_color != fill_color_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(balloon)
		reversion.data.fill_color = fill_color_before_changes
		Comic.book.add_undo_step([reversion])

func _on_fill_color_revert():
	if balloon.data.has("fill_color"):
		Comic.book.add_undo_step([ComicReversionData.new(balloon)])
		balloon.data.erase("fill_color")
		_after_fill_color_change()
		fill_color_button.color = balloon.fill_color

func _after_fill_color_change():
	balloon.rebuild(true)
	if balloon.is_default("fill_color"):
		fill_color_revert_button.hide()
	else:
		fill_color_revert_button.show()
		
func _on_font_color_opened():
	font_color_before_changes = balloon.font_color

func _on_font_color_changed(color:Color):
	balloon.font_color = color
	_after_font_color_change()

func _on_font_color_closed():
	if balloon.font_color != font_color_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(balloon)
		reversion.data.font_color = font_color_before_changes
		Comic.book.add_undo_step([reversion])

func _on_font_color_revert():
	if balloon.data.has("font_color"):
		Comic.book.add_undo_step([ComicReversionData.new(balloon)])
		balloon.data.erase("font_color")
		_after_font_color_change()
		font_color_button.color = balloon.font_color

func _after_font_color_change():
	balloon.rebuild(true)
	if balloon.is_default("font_color"):
		font_color_revert_button.hide()
	else:
		font_color_revert_button.show()
		
	
