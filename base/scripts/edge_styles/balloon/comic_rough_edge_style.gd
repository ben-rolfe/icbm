class_name ComicRoughEdgeStyle
extends ComicEdgeStyle

const FORCE:float = 0.5

func _init():
	id = "rough"
	editor_name = "Rough"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "edge_rough.svg"))
	is_randomized = true
	tail_style_id = "rough"

func calculate_points(balloon:ComicBalloon):
	if balloon.edge_offsets.size() > 0:
		balloon.edge_points = PackedVector2Array()
		for i in balloon.edge_offsets.size():
			balloon.edge_points.push_back(balloon.center_point + balloon.edge_offsets[i] + balloon.shape.get_edge_transform(balloon, balloon.edge_offset_angles[i]).y * balloon.edge_segment_length * balloon.rng.randf_range(-FORCE, FORCE))
