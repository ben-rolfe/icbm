class_name ComicLayer
extends Control

var depth:int

func _init(_name:String, _depth:int):
	name = _name
	depth = _depth

func _draw():
	# First we draw all the edges
	for child in get_children():
		if child.has_method("draw_edge"):
			child.draw_edge(self)
	#for line in _lines:
		#if line.points.size() > 1:
			#draw_polyline(line.points, line.edge_color, line.fill_width + 2 * line.edge_width, true)
	#for child in get_children():
		#if child is ComicBalloon:
			#child.draw_edge(self)

	# Then we draw all the fills
	for child in get_children():
		if child.has_method("draw_fill"):
			child.draw_fill(self)
	#for line in _lines:
		#if line.points.size() > 1:
			#draw_polyline(line.points, line.fill_color, line.fill_width, true)
	#for child in get_children():
		#if child is ComicBalloon:
			#child.draw_fill(self)

	# And the labels go on top of the fills.
	for child in get_children():
		if child.has_method("draw_over"):
			child.draw_over(self)
	#for child in get_children():
		#if child is ComicLabel:
			#child.draw(self)


#func add_line_from_params(params: Dictionary):
	#theme = preload("res://theme/root_theme.tres")
#
	#if params.has("clear"):
		#_lines = []
	#var line: Dictionary = {
		#"points": [],
		#"fill_width": (float(params.fill_width) * Comic.px_per_unit) if params.has("fill_width") else theme.get_constant("fill_width", "Frame"),
		#"fill_color": params.fill_color if params.has("fill_color") else theme.get_color("fill_color", "Frame"),
		#"edge_width": (float(params.edge_width) * Comic.px_per_unit) if params.has("edge_width") else theme.get_constant("edge_width", "Frame"),
		#"edge_color": params.edge_color if params.has("line_color") else theme.get_color("edge_color", "Frame"),
	#}
	#var j = 0
	#while params.has(j):
		#line.points.push_back(Comic.execute(str("Vector2(", params[j], ")")))
		#j += 1
		#
	#if not params.has("units_are_pixels") or not Comic.parse_boolean(params.units_are_pixels):
		#for i in line.points.size():
			#line.points[i] *= Comic.px_per_unit
	#_lines.push_back(line)
#
#func add_balloon_from_params(params:Dictionary):
	#var balloon:ComicBalloon = ComicEditorBalloon.new(ComicEditorBalloon.params_to_data(params)) if Comic.book is ComicEditor else ComicBalloon.new(ComicBalloon.params_to_data(params))
	#add_child(balloon)
#
#func add_label_from_params(params:Dictionary):
	#var label = ComicLabel.new(ComicLabel.params_to_data(params))
	#add_child(label)

