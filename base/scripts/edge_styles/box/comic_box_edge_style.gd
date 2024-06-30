class_name ComicBoxEdgeStyle
extends ComicEdgeStyle

func _init():
	shape_id = "box"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "shape_box.svg"))

func calculate_offsets(balloon:ComicBalloon):
	balloon.edge_offsets = PackedVector2Array()
	balloon.edge_offsets.push_back(Vector2(-balloon.frame_half_size.x - balloon.padding.x, -balloon.frame_half_size.y - balloon.padding.y))
	balloon.edge_offsets.push_back(Vector2(balloon.frame_half_size.x + balloon.padding.z, -balloon.frame_half_size.y - balloon.padding.y))
	balloon.edge_offsets.push_back(Vector2(balloon.frame_half_size.x + balloon.padding.z, balloon.frame_half_size.y + balloon.padding.w))
	balloon.edge_offsets.push_back(Vector2(-balloon.frame_half_size.x - balloon.padding.x, balloon.frame_half_size.y + balloon.padding.w))
	balloon.edge_offsets.push_back(balloon.edge_offsets[0])
