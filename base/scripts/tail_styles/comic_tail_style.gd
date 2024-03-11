class_name ComicTailStyle
extends RefCounted

var id:String = "smooth"
var editor_name:String = "Smooth"
var editor_icon:Texture2D = load(str(ComicEditor.DIR_ICONS, "tail_smooth.svg"))
var is_randomized:bool
var supports_tips:bool = true

func get_spine_points(tail:ComicTail) -> Array[Transform2D]:
	# Both get_baked_points and tesselate kind of suck for our needs - they both increase points in big jumps (perhaps only when the counts are small?) by adding a point between each current point,
	# so the point count goes from 2 -> 3 -> 5 -> 9 -> 17, which results in really variable segment length.
	# For that reason. we do our own spacing. We can't trust sample for this, either, because that is highly distorted by in and out points, so we're stuck with iterating over a hidev bake.
	var curve:Curve2D = get_base_curve(tail)
	var hidef_points:PackedVector2Array = curve.get_baked_points()
	var num_points:int = max(2, floori(curve.get_baked_length() / Comic.EDGE_SEGMENT_LENGTH))
	var adjusted_segment_length:float = curve.get_baked_length() / num_points
	var d:float = 0
	var points:PackedVector2Array = PackedVector2Array()
	for i in range(1, hidef_points.size()):
		d += hidef_points[i].distance_to(hidef_points[i-1])
		if d / adjusted_segment_length > points.size():
			points.push_back(hidef_points[i])
	if points.size() > 0:
		if points[-1].distance_to(hidef_points[-1]) > adjusted_segment_length * 0.5:
			# Looks like we should add another point
			points.push_back(hidef_points[-1])
		else:
			# Let's just adjust the final point.
			points[-1] = hidef_points[-1]
	return points_to_transforms(points)

func get_base_curve(tail:ComicTail) -> Curve2D:
	var curve:Curve2D = Curve2D.new()
	curve.bake_interval = 1
	curve.add_point(tail.p_start + tail.inset_start, Vector2.ZERO, tail.v_start)
	curve.add_point(tail.p_end + tail.inset_end, tail.v_end, Vector2.ZERO)
	return curve

func points_to_transforms(points:PackedVector2Array) -> Array[Transform2D]:
	var transforms:Array[Transform2D] = []
	for i in points.size():
		transforms.push_back(Transform2D((points[min(points.size() - 1, i + 1)] - points[max(0, i - 1)]).angle(), points[i]))
	return transforms

func get_edge_colors(tail:ComicTail) -> PackedColorArray:
	var colors = PackedColorArray()
	#TODO: Fix inset tails
	var n:int = tail.edge_points.size() / 2
	# Build half the array, from the end point to the start
	for i in n:
		colors.push_back(tail.edge_color_end.lerp(tail.edge_color_start, i / float(n)))
	# Now append a mirror, looping back to the end point
	for i in range(colors.size() - 1, -1, -1):
		colors.push_back(colors[i])
	return colors

func get_fill_colors(tail:ComicTail) -> PackedColorArray:
	var colors = PackedColorArray()
	var n:int = tail.edge_points.size() / 2
	# Build half the array, from the end point to the start
	for i in n:
		colors.push_back(tail.fill_color_end.lerp(tail.fill_color_start, i / float(n)))
	# Now append a mirror, looping back to the end point
	for i in range(colors.size() - 1, -1, -1):
		colors.push_back(colors[i])
	return colors

func draw_under(tail:ComicTail, layer:ComicLayer):
	if tail.under_points.size() > 0:
		layer.draw_polyline(tail.under_points, tail.edge_color_end, tail.edge_thickness * 2)
		layer.draw_colored_polygon(tail.under_points, tail.fill_color_end)

func draw_edge(tail:ComicTail, layer:ComicLayer):
	if tail.edge_color_start == tail.edge_color_end:
		layer.draw_polyline(tail.edge_points, tail.edge_color_start, tail.edge_thickness * 2)
	else:
		layer.draw_polyline_colors(tail.edge_points, get_edge_colors(tail), tail.edge_thickness * 2)

func draw_fill(tail:ComicTail, layer:ComicLayer, called_by_linked_layer:bool = false):
	if tail.fill_color_start == tail.fill_color_end:
		layer.draw_colored_polygon(tail.edge_points, tail.fill_color_start)
	else:
		layer.draw_polygon(tail.edge_points, get_fill_colors(tail))

func adjust_points(tail:ComicTail):
	pass
