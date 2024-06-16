class_name ComicEditorImageProperties
extends ComicEditorProperties

var image:ComicEditorImage
@export var anchor_button:OptionButton
@export var flip_check_box:CheckBox

@export var tint_button:ColorPickerButton
@export var tint_revert_button:Button
var tint_before_changes:Color


func _ready():
	for key in Comic.ANCHOR_POINTS:
		anchor_button.add_icon_item(load(str(ComicEditor.DIR_ICONS, "anchor_", key.to_lower(), ".svg")), key)
		anchor_button.set_item_metadata(-1, Comic.ANCHOR_POINTS[key])
	anchor_button.item_selected.connect(_on_anchor_button_item_selected)

	flip_check_box.toggled.connect(_on_flip_check_box_toggled)

	tint_button.pressed.connect(_on_tint_opened)
	tint_button.color_changed.connect(_on_tint_changed)
	tint_button.popup_closed.connect(_on_tint_closed)
	tint_revert_button.pressed.connect(_on_tint_revert)
	tint_revert_button.modulate = Color.BLACK
	
func prepare():
	super()
	image = Comic.book.selected_element
	for i in Comic.ANCHOR_POINTS.size():
		if Comic.ANCHOR_POINTS.values()[i] == image.anchor_to:
			anchor_button.select(i)
			break
			
	flip_check_box.button_pressed = image.flip

	tint_button.color = image.tint
	_after_tint_change()

			
func _on_anchor_button_item_selected(index:int):
	image.anchor_to = anchor_button.get_item_metadata(index)
	image.rebuild(true)

func _on_flip_check_box_toggled(toggled_on:bool):
	image.flip = toggled_on
	image.rebuild(true)

func _on_tint_opened():
	tint_before_changes = image.tint

func _on_tint_changed(color:Color):
	image.tint = color
	_after_tint_change()

func _on_tint_closed():
	if image.tint != tint_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(image)
		reversion.data.tint = tint_before_changes
		Comic.book.add_undo_step([reversion])

func _on_tint_revert():
	if image.data.has("tint"):
		Comic.book.add_undo_step([ComicReversionData.new(image)])
		image.data.erase("tint")
		_after_tint_change()
		tint_button.color = image.tint

func _after_tint_change():
	image.rebuild(true)
	if image.is_default("tint"):
		tint_revert_button.hide()
	else:
		tint_revert_button.show()
