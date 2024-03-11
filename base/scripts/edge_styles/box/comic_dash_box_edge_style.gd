class_name ComicDashBoxEdgeStyle
extends ComicBoxEdgeStyle

func _init():
	super()
	id = "dash"
	editor_name = "Dash"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "edge_dash_box.svg"))
	tail_style_id = "dash"
	segment_divisor = 4

func calculate_points(balloon:ComicBalloon):
	if balloon.edge_offsets.size() > 0:
		for i in balloon.edge_offsets.size() - 1:
			var segments:int = snapped(balloon.edge_offsets[i].distance_to(balloon.edge_offsets[i + 1]) / balloon.edge_segment_length, segment_divisor)
			for j in segments:
				balloon.edge_points.push_back(balloon.center_point + balloon.edge_offsets[i].lerp(balloon.edge_offsets[i + 1], j / float(segments)))

func draw_edge(balloon:ComicBalloon, layer:ComicLayer):
	if balloon.edge_points.size() > 0:
		for i in range(0, balloon.edge_points.size(), 4):
			layer.draw_line(balloon.edge_points[i - 1], balloon.edge_points[i - 2], balloon.edge_color, balloon.edge_thickness * 2.0, true)
			layer.draw_line(balloon.edge_points[i - 2], balloon.edge_points[i - 3], balloon.edge_color, balloon.edge_thickness * 2.0, true)
