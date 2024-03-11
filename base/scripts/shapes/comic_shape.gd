class_name ComicShape
extends RefCounted
# Parent class for shapes which may be applied to balloons.

var id:String = "balloon"
var editor_name:String = "Balloon"
var editor_icon:Texture2D = load(str(ComicEditor.DIR_ICONS, "shape_balloon.svg"))
var center_adjustment:Vector2

func adjust_frame_half_size(balloon:ComicBalloon):
	# For round balloons, we unsquish the corner points a bit (while leaving their contents untouched)
	# This won't have much effect unless the balloon is very squished 
	var long_side:float
	var short_side:float
	var adjustment_direction
	if balloon.frame_half_size.x > balloon.frame_half_size.y:
		long_side = balloon.frame_half_size.x
		short_side = balloon.frame_half_size.y
		adjustment_direction = Vector2(-1,1)
	else:
		long_side = balloon.frame_half_size.y
		short_side = balloon.frame_half_size.x
		adjustment_direction = Vector2(1,-1)
	balloon.frame_half_size += adjustment_direction * (long_side / short_side * long_side / 100.0)
	pass

func get_edge_transform(balloon:ComicBalloon, angle:float) -> Transform2D:
	angle = fposmod(angle, TAU)
	for i in balloon.edge_offsets.size():
		if balloon.edge_offset_angles[i] > angle:
			#Note that this could be better - it's currently just finding th halfway point betweent the two closes offsets. But I think it's good enough?
			return Transform2D((balloon.edge_offsets[i - 1] - balloon.edge_offsets[i]).angle(), (balloon.edge_offsets[i - 1] + balloon.edge_offsets[i]) / 2)
	return Transform2D.IDENTITY

func get_edge_offset(balloon:ComicBalloon, circle_angle:float) -> Vector2:
	# NOTE: This does not get the offset at the given angle!
	# The given angle is the circle angle - the angle to the point on the original circle BEFORE we squish it.
	# If you want to get the offset at a given angle, use get_edge_transform().origin
	var sin_t:float = sin(circle_angle)
	var cos_t:float = cos(circle_angle)
	# Calculate the point at angle t for an ellipse that touches the corners of the box
	var point:Vector2 = Comic.ROOT2 * Vector2(balloon.frame_half_size.x * cos_t, balloon.frame_half_size.y * sin_t)
	if balloon.squirk != 0:
		#Adjust the point if we want a squircle, not an ellipse
		var squoval_point:Vector2 = Comic.QUARTIC2 * Vector2(balloon.frame_half_size.x * sqrt(abs(cos_t)) * sign(cos_t), balloon.frame_half_size.y * sqrt(abs(sin_t)) * sign(sin_t))
		point = point.lerp(squoval_point, balloon.squirk)
	return point

func has_point(balloon:ComicBalloon, global_point:Vector2) -> bool:
	return balloon.center_point.distance_squared_to(global_point) < get_edge_transform(balloon, (global_point - balloon.center_point).angle()).origin.length_squared()
