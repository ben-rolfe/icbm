class_name ComicImageEdgeStyle
extends ComicBoxEdgeStyle

func _init():
	id = "image"
	shape_id = "image"
	editor_name = "Image"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "image.svg"))
	tail_style_id = "cloud"

func calculate_points(_balloon:ComicBalloon):
	pass
	
func calculate_offsets(_balloon:ComicBalloon):
	pass

func calculate_offset_angles(_balloon:ComicBalloon):
	pass

func draw_edge(_balloon:ComicBalloon, _layer:ComicLayer):
	pass
	
func draw_fill(_balloon:ComicBalloon, _layer:ComicLayer):
	pass

