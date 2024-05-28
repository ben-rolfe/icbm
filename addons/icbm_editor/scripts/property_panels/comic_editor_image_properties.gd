class_name ComicEditorImageProperties
extends ComicEditorProperties

var image:ComicEditorImage
@export var anchor_button:OptionButton

func _ready():
	for key in Comic.ANCHOR_POINTS:
		anchor_button.add_icon_item(load(str(ComicEditor.DIR_ICONS, "anchor_", key.to_lower(), ".svg")), key)
		anchor_button.set_item_metadata(-1, Comic.ANCHOR_POINTS[key])
	anchor_button.item_selected.connect(_on_anchor_button_item_selected)
	
func prepare():
	super()
	image = Comic.book.selected_element
	for i in Comic.ANCHOR_POINTS.size():
		if Comic.ANCHOR_POINTS.values()[i] == image.anchor_to:
			anchor_button.select(i)
			break
			
func _on_anchor_button_item_selected(index:int):
	image.anchor_to = anchor_button.get_item_metadata(index)
	image.rebuild(true)