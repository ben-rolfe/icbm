class_name ComicRoughBoxEdgeStyle
extends ComicBoxEdgeStyle

const FORCE:float = 0.5

func _init():
	super()
	id = "rough"
	editor_name = "Rough"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "edge_rough_box.svg"))
	is_randomized = true
	tail_style_id = "rough"

func calculate_points(balloon:ComicBalloon):
	if balloon.edge_offsets.size() > 0:
		var angle:float = TAU * 0.5
		for i in balloon.edge_offsets.size() - 1:
			var segments:int = snapped(balloon.edge_offsets[i].distance_to(balloon.edge_offsets[i + 1]) / balloon.edge_segment_length, segment_divisor)
			for j in segments:
				if j < 2:
					# Rotate by 45 degrees for the corner, then again for the first edge point
					angle += TAU * 0.125
				balloon.edge_points.push_back(balloon.center_point + balloon.edge_offsets[i].lerp(balloon.edge_offsets[i + 1], j / float(segments)) + Vector2.from_angle(angle) * (balloon.rng.randf_range(-FORCE, FORCE) * balloon.edge_segment_length))
		balloon.edge_points.push_back(balloon.edge_points[0]) # Close the shape
