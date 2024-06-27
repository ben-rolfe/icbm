class_name ComicDashTailStyle
extends ComicTailStyle

func _init():
	id = "dash"
	editor_name = "Dash"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "tail_dash.svg"))

func draw_edge(tail:ComicTail, layer:ComicLayer):
	var color = tail.edge_color_end
	var n = tail.edge_points.size()
	for i in range(0, n, 4):
		if tail.edge_color_start != tail.edge_color_end:
			color = tail.edge_color_start.lerp(tail.edge_color_end, abs(n - i * 2) / float(n - 1))
		layer.draw_line(tail.edge_points[i], tail.edge_points[i - 1], color, tail.edge_thickness * 2.0)
		layer.draw_line(tail.edge_points[i - 1], tail.edge_points[i - 2], color, tail.edge_thickness * 2.0)
