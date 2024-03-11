class_name ComicEdgeStyle
extends RefCounted

var id:String = "smooth"
var shape_id:String = "balloon"
var tail_style_id:String = "smooth"
var editor_name:String = "Smooth"
var editor_icon:Texture2D = load(str(ComicEditor.DIR_ICONS, "edge_smooth.svg"))
var is_randomized:bool
var tail_inset_multiplier:float = 0
var segment_divisor:int = 1

func calculate_offsets(balloon:ComicBalloon):
	# We're dealing with a rounded shape. The basic idea goes like this:
	# Step 1: Create a whole lot of points for a really high definition version of the shape.
	# Step 2: Calculate the distance between each of those points, and the total difference around the shape.
	# Step 3: Calculate the best length of each edge segment, based on the ideal edge length (as set in the root theme), the total edge length, and the multiple of edge segments we need (e.g. our edge style might need us to have a number of edge segments that is divisible by 8, or whatever)
	# Step 4: Go around the high def shape, creating a low def shape with less points, with approximately the right length of edge segment between each pair of points.
	# Note that, for ease, we create the whole shape around (0,0) and add the box_center to each point at the end.
	# Also note that yes, I did try using Curve2D for this, but the inconsistencies in sampled points made for really ugly edge patterns, especially around the pointy ends of one-line balloons

	var hidef_offsets:Array[Vector2] = []
	var hidef_distance:Array[float] = []
	# Note: TAU is being used in this formula, not PI, because we're using the radius (_box_half_size) not the diameter
	var approx_perimeter:float = TAU * (3 * sqrt(2) * (balloon.frame_half_size.x + balloon.frame_half_size.y) - sqrt(sqrt(2) * (3 * balloon.frame_half_size.x + balloon.frame_half_size.y) * (balloon.frame_half_size.x + 3 * balloon.frame_half_size.y)))
	
	var hidef_multiplier:int = Comic.theme.get_constant("hidef_multiplier", "Settings")
	var hidef_res:int = roundi(approx_perimeter / balloon.edge_segment_length * hidef_multiplier)

	for i in range(hidef_res):
		var point:Vector2 = balloon.shape.get_edge_offset(balloon, TAU * float(i) / hidef_res)
		if i == 0:
			hidef_distance.push_back(0)
		else:
			hidef_distance.push_back(hidef_distance[-1] + point.distance_to(hidef_offsets[-1]))
		hidef_offsets.push_back(point)
	if hidef_offsets.size() > 0:
		var hidef_length:float = hidef_distance[-1] + hidef_offsets[-1].distance_to(hidef_offsets[0])

		# Calculate the low def edge offsets
		# Note that we need to do this even if we're not using them for the shape (as is the case for EdgeStyle.BURST, for example) because we use them in get_edge_transform
		# Calculate best number of segments
		var num_segments:int = roundi(hidef_length / balloon.edge_segment_length)
		if segment_divisor > 1:
			# Ensure that the number of segments is a multiple of the segment_divisor (so that, for example, a dotted edge meets nicely at the ends)
			num_segments = segment_divisor * (num_segments / segment_divisor)
		var adjusted_segment_length = hidef_length / num_segments

		for i in hidef_distance.size():
			if hidef_distance[i] >= balloon.edge_offsets.size() * adjusted_segment_length:
				balloon.edge_offsets.push_back(hidef_offsets[i])
		balloon.edge_offsets.push_back(balloon.edge_offsets[0])
	
func calculate_offset_angles(balloon:ComicBalloon):
	if balloon.edge_offsets.size() > 0:
		for i in balloon.edge_offsets.size():
			balloon.edge_offset_angles.push_back(fposmod(balloon.edge_offsets[i].angle(), TAU))
		balloon.edge_offset_angles[-1] = TAU # The last point should be TAU, not 0

func calculate_points(balloon:ComicBalloon):
	if balloon.edge_offsets.size() > 0:
		balloon.edge_points = PackedVector2Array()
		for i in balloon.edge_offsets.size():
			balloon.edge_points.push_back(balloon.edge_offsets[i] + balloon.center_point)

func draw_edge(balloon:ComicBalloon, layer:ComicLayer):
	if balloon.edge_points.size() > 0:
		layer.draw_polyline(balloon.edge_points, balloon.edge_color, balloon.edge_thickness * 2, true)

func draw_fill(balloon:ComicBalloon, layer:ComicLayer):
	if balloon.edge_points.size() > 0:
		layer.draw_colored_polygon(balloon.edge_points, balloon.fill_color)
