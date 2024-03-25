class_name ComicCloudTailStyle
extends ComicTailStyle

const SPACING:int = 8
const OUTSET:float = 2
# Without this multiplier, the edges of the circles looked too thin. I'm not sure why - perhaps an antialiasing effect?. Drawing the edge with draw_arc instead didn't help.
#TODO: Consider trying draw_polyline
const EDGE_THICKNESS_CORRECTION = 1.2

func _init():
	id = "cloud"
	editor_name = "Cloud"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "tail_cloud.svg"))
	supports_tips = false

func get_base_curve(tail:ComicTail) -> Curve2D:
	# We don't inset; instead we outset a bit. Also, we set the bake interval to bake a high definition curve - we'll apply our own spacing.
	var curve:Curve2D = Curve2D.new()
	curve.add_point(tail.p_start + tail.v_start.normalized() * (Comic.EDGE_SEGMENT_LENGTH * OUTSET), Vector2.ZERO, tail.v_start)
	curve.add_point((tail.p_end + tail.v_end.normalized() * (Comic.EDGE_SEGMENT_LENGTH * OUTSET)) if tail.data.linked else tail.p_end, tail.v_end, Vector2.ZERO)
	return curve

func adjust_points(tail:ComicTail):
	# This tail style doesn't support tips, so get_spine_points was never called, and edge_points haven't been set, yet.
	# We have to do our own spacing, as getting them from bake or tesselate will go straight from 3 points to 5 to 9, etc. (placing midpoints between existing points)
	var curve:Curve2D = get_base_curve(tail)
	var length:float = curve.get_baked_length()
	var num_points:int = max(3, floori(length / (Comic.EDGE_SEGMENT_LENGTH * SPACING)))
	var points:PackedVector2Array = PackedVector2Array()
	for i in num_points:
		points.push_back(curve.sample(0, i / float(num_points - 1)))
	tail.edge_points = points
	
func draw_edge(_tail:ComicTail, _draw_layer:ComicLayer):
	pass
	
func draw_fill(tail:ComicTail, draw_layer:ComicLayer):
	var color:Color
	# In case of overlap, points nearer the start should be drawn last (on top)
	for i in range(tail.edge_points.size() - 1, -1, -1):
		var t = i / float(tail.edge_points.size() - 1)
		color = tail.edge_color_start.lerp(tail.edge_color_end, t)
		draw_layer.draw_circle(tail.edge_points[i], Comic.tail_width * (1 - t * 0.5) + tail.edge_thickness * EDGE_THICKNESS_CORRECTION, color)
		color = tail.fill_color_start.lerp(tail.fill_color_end, t)
		draw_layer.draw_circle(tail.edge_points[i], Comic.tail_width * (1 - t * 0.5), color)
