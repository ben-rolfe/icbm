class_name ComicBoxEdgeStyle
extends ComicEdgeStyle

func _init():
	shape_id = "box"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "shape_box.svg"))

func calculate_offsets(balloon:ComicBalloon):
	balloon.edge_offsets = PackedVector2Array()
	balloon.edge_offsets.push_back(-balloon.frame_half_size)
	balloon.edge_offsets.push_back(Vector2(balloon.frame_half_size.x, -balloon.frame_half_size.y))
	balloon.edge_offsets.push_back(balloon.frame_half_size)
	balloon.edge_offsets.push_back(Vector2(-balloon.frame_half_size.x, balloon.frame_half_size.y))
	balloon.edge_offsets.push_back(balloon.edge_offsets[0])
