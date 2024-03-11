class_name ComicDashEdgeStyle
extends ComicEdgeStyle

func _init():
	id = "dash"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "edge_dash.svg"))
	editor_name = "Dash"
	segment_divisor = 4
	tail_style_id = "dash"

func draw_edge(balloon:ComicBalloon, layer:ComicLayer):
	if balloon.edge_points.size() > 0:
		for i in range(0, balloon.edge_points.size(), 4):
			layer.draw_line(balloon.edge_points[i], balloon.edge_points[i - 1], balloon.edge_color, balloon.edge_thickness * 2.0, true)
			layer.draw_line(balloon.edge_points[i - 1], balloon.edge_points[i - 2], balloon.edge_color, balloon.edge_thickness * 2.0, true)
