class_name ComicZagTailStyle
extends ComicZigTailStyle

func _init():
	id = "zag"
	editor_name = "Zag"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "tail_zag.svg"))
	shift *= -1
