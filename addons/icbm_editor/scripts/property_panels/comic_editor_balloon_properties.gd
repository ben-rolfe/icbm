class_name ComicEditorBalloonProperties
extends ComicEditorProperties

@export var oid_label:Label

@export var text_edit:TextEdit
var balloon:ComicEditorBalloon
var text_before_changes:String

@export var font_color_button:ColorPickerButton
@export var font_color_revert_button:Button
var font_color_before_changes:Color

@export var font_button:OptionButton

@export var shape_button:OptionButton

@export var edge_style_row:HBoxContainer
@export var edge_style_button:OptionButton
@export var edge_color_row:HBoxContainer
@export var edge_color_button:ColorPickerButton
@export var edge_color_revert_button:Button
var edge_color_before_changes:Color

@export var fill_color_button:ColorPickerButton
@export var fill_color_revert_button:Button
var fill_color_before_changes:Color

@export var align_button:OptionButton
@export var anchor_button:OptionButton

@export var shown_check_box:CheckBox
@export var appear_spin_box:SpinBox
@export var appear_button:OptionButton
@export var disappear_spin_box:SpinBox
@export var disappear_button:OptionButton

@export var padding_l_spin_box:SpinBox
@export var padding_t_spin_box:SpinBox
@export var padding_r_spin_box:SpinBox
@export var padding_b_spin_box:SpinBox

@export var image_row:HBoxContainer
@export var image_button:OptionButton
@export var nine_slice_row:HBoxContainer
@export var nine_slice_l_spin_box:SpinBox
@export var nine_slice_t_spin_box:SpinBox
@export var nine_slice_r_spin_box:SpinBox
@export var nine_slice_b_spin_box:SpinBox


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

	for file_name in DirAccess.get_files_at(str(Comic.DIR_FONTS, "balloon")):
		font_button.add_item(file_name.get_basename().capitalize())
		font_button.set_item_metadata(font_button.item_count - 1, file_name.get_basename())
	font_button.item_selected.connect(_on_font_button_item_selected)

	for key in Comic.HORIZONTAL_ALIGNMENTS:
		align_button.add_item(key)
		align_button.set_item_metadata(-1, Comic.HORIZONTAL_ALIGNMENTS[key])
	for key in Comic.shapes:
		shape_button.add_icon_item(Comic.shapes[key].editor_icon, key)
		
	shape_button.item_selected.connect(_on_shape_button_item_selected)
	edge_style_button.item_selected.connect(_on_edge_style_button_item_selected)

	for key in Comic.HORIZONTAL_ALIGNMENTS:
		align_button.add_item(key)
		align_button.set_item_metadata(-1, Comic.HORIZONTAL_ALIGNMENTS[key])
	align_button.item_selected.connect(_on_align_button_item_selected)

	for key in Comic.ANCHOR_POINTS:
		anchor_button.add_icon_item(load(str(ComicEditor.DIR_ICONS, "anchor_", key.to_lower(), ".svg")), key)
		anchor_button.set_item_metadata(-1, Comic.ANCHOR_POINTS[key])
	anchor_button.item_selected.connect(_on_anchor_button_item_selected)

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

	padding_l_spin_box.value_changed.connect(_set_padding.bind(0))
	padding_t_spin_box.value_changed.connect(_set_padding.bind(1))
	padding_r_spin_box.value_changed.connect(_set_padding.bind(2))
	padding_b_spin_box.value_changed.connect(_set_padding.bind(3))
	
	image_button.add_item("")
	for file_name in Comic.get_images_file_names():
		image_button.add_item(file_name)
	image_button.item_selected.connect(_on_image_button_item_selected)

	nine_slice_l_spin_box.value_changed.connect(_set_nine_slice.bind(0))
	nine_slice_t_spin_box.value_changed.connect(_set_nine_slice.bind(1))
	nine_slice_r_spin_box.value_changed.connect(_set_nine_slice.bind(2))
	nine_slice_b_spin_box.value_changed.connect(_set_nine_slice.bind(3))
	
func prepare():
	super()
	balloon = Comic.book.selected_element
	oid_label.text = str("oid: ", balloon.oid)
	text_edit.text = ComicEditor.parse_text_edit(balloon.content)
	text_edit.grab_focus()
	if text_edit.text == Comic.default_presets.balloon[""].content:
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

	for i in font_button.item_count:
		if font_button.get_item_metadata(i) == balloon.font:
			font_button.select(i)
			break

	for i in shape_button.item_count:
		if shape_button.get_item_text(i) == balloon.shape.id:
			shape_button.select(i)
			break
	_after_set_shape()

	for i in Comic.HORIZONTAL_ALIGNMENTS.values().size():
		if Comic.HORIZONTAL_ALIGNMENTS.values()[i] == balloon.align:
			align_button.select(i)
			break

	for i in Comic.ANCHOR_POINTS.size():
		if Comic.ANCHOR_POINTS.values()[i] == balloon.anchor_to:
			anchor_button.select(i)
			break
	
	shown_check_box.button_pressed = balloon.shown
	appear_spin_box.value = balloon.appear
	appear_button.select(balloon.appear_type)
	if balloon.appear_type == 0:
		appear_spin_box.hide()
	else:
		appear_spin_box.show()
		
	disappear_spin_box.value = balloon.disappear
	disappear_button.select(balloon.disappear_type)
	if balloon.disappear_type == 0:
		disappear_spin_box.hide()
	else:
		disappear_spin_box.show()

	padding_l_spin_box.value = balloon.padding.x
	padding_t_spin_box.value = balloon.padding.y
	padding_r_spin_box.value = balloon.padding.z
	padding_b_spin_box.value = balloon.padding.w
	
	for i in image_button.item_count:
		if image_button.get_item_text(i) == balloon.image:
			image_button.select(i)
			break
	
	nine_slice_l_spin_box.value = balloon.nine_slice.x
	nine_slice_t_spin_box.value = balloon.nine_slice.y
	nine_slice_r_spin_box.value = balloon.nine_slice.z
	nine_slice_b_spin_box.value = balloon.nine_slice.w

func _on_text_changed():
	balloon.content = ComicEditor.unparse_text_edit(text_edit.text)
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
	if not balloon.is_default("font_color"):
		Comic.book.add_undo_step([ComicReversionData.new(balloon)])
		balloon.clear_data("font_color")
		_after_font_color_change()
		font_color_button.color = balloon.font_color

func _after_font_color_change():
	balloon.rebuild(true)
	if balloon.is_default("font_color"):
		font_color_revert_button.hide()
	else:
		font_color_revert_button.show()
	
func _on_align_button_item_selected(index:int):
	Comic.book.add_undo_step([ComicReversionData.new(balloon)])
	balloon.align = align_button.get_item_metadata(index)
	balloon.rebuild(true)

func _on_anchor_button_item_selected(index:int):
	Comic.book.add_undo_step([ComicReversionData.new(balloon)])
	balloon.anchor_to = anchor_button.get_item_metadata(index)
	balloon.rebuild(true)

func _on_shown_check_box_toggled(toggled_on:bool):
	Comic.book.add_undo_step([ComicReversionData.new(balloon)])
	balloon.shown = toggled_on

func _on_appear_button_item_selected(index:int):
	if index == 0:
		# We don't have an undo step here, because the next line will trigger one
		appear_spin_box.value = 0
		appear_spin_box.hide()
	else:
		Comic.book.add_undo_step([ComicReversionData.new(balloon)])
		appear_spin_box.show()
	balloon.appear_type = appear_button.get_item_metadata(index)

func _on_disappear_button_item_selected(index:int):
	if index == 0:
		# We don't have an undo step here, because the next line will trigger one
		disappear_spin_box.value = 0
		disappear_spin_box.hide()
	else:
		Comic.book.add_undo_step([ComicReversionData.new(balloon)])
		disappear_spin_box.show()
	balloon.disappear_type = disappear_button.get_item_metadata(index)
		
func _on_appear_spin_box_value_changed(value:int):
	Comic.book.add_undo_step([ComicReversionData.new(balloon)])
	balloon.appear = value

func _on_disappear_spin_box_value_changed(value:int):
	Comic.book.add_undo_step([ComicReversionData.new(balloon)])
	balloon.disappear = value
	
func _set_padding(value:int, i:int):
	Comic.book.add_undo_step([ComicReversionData.new(balloon)])
	# balloon.padding is a property which returns BY VALUE the value stored in the _data dictionary - NOT a reference to it 
	var v:Vector4i = balloon.padding
	v[i] = value
	balloon.padding = v
	balloon.rebuild(false)
	
func _set_nine_slice(value:int, i:int):
	Comic.book.add_undo_step([ComicReversionData.new(balloon)])
	# balloon.nine_slice is a property which returns BY VALUE the value stored in the _data dictionary - NOT a reference to it 
	var v:Vector4i = balloon.nine_slice
	v[i] = value
	balloon.nine_slice = v
	balloon.rebuild(false)
	
func _after_set_shape():
	# We change the edge style to one of the same name for the new shape (if available, or the default if not.
	balloon.edge_style = Comic.get_edge_style(balloon.shape.id, balloon.edge_style.id)

	if balloon.shape.editor_show_edge_options:
		edge_style_row.show()
		edge_color_row.show()
	else:
		edge_style_row.hide()
		edge_color_row.hide()
	if balloon.shape.editor_show_image_options:
		image_row.show()
		nine_slice_row.show()
	else:
		image_row.hide()
		nine_slice_row.hide()

	# Then we rebuild the edge_style dropdown
	edge_style_button.clear()
	var i = 0
	for key in Comic.edge_styles[balloon.shape.id]:
		edge_style_button.add_icon_item(Comic.edge_styles[balloon.shape.id][key].editor_icon, key)
		if key == balloon.edge_style.id:
			edge_style_button.select(i)
		i += 1

func _on_shape_button_item_selected(index:int):
	Comic.book.add_undo_step([ComicReversionData.new(balloon)])
	balloon.shape = Comic.get_shape(shape_button.get_item_text(index))
	_after_set_shape()
	balloon.rebuild(true)
	
func _on_edge_style_button_item_selected(index:int):
	Comic.book.add_undo_step([ComicReversionData.new(balloon)])
	balloon.edge_style = Comic.get_edge_style(balloon.shape.id, edge_style_button.get_item_text(index))
	balloon.rebuild(true)

func _on_image_button_item_selected(index:int):
	Comic.book.add_undo_step([ComicReversionData.new(balloon)])
	balloon.image = image_button.get_item_text(index)
	balloon.rebuild(true)

func _on_font_button_item_selected(index:int):
	Comic.book.add_undo_step([ComicReversionData.new(balloon)])
	balloon.font = font_button.get_item_metadata(index)
	balloon.rebuild(true)
