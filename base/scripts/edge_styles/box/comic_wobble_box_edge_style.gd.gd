class_name ComicWobbleBoxEdgeStyle
extends ComicBoxEdgeStyle

const ANGLE:float = TAU / 32
const FORCE:float = 8
func _init():
	super()
	id = "wobble"
	editor_name = "Wobble"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "edge_burst_box.svg"))
	is_randomized = true
	tail_style_id = "wobble"

func calculate_points(balloon:ComicBalloon):
	if balloon.edge_offsets.size() > 0:
		# Prepare for the sub-curves
		var curve:Curve2D = Curve2D.new()
		curve.bake_interval = balloon.edge_segment_length
		var tangent = Vector2.DOWN
		# Force is half the shortest edge, or a quarter of the longest (since it will get split in half by a point), whichever is shortest
		var force = min(balloon.frame_half_size.x, balloon.frame_half_size.y, max(balloon.frame_half_size.x, balloon.frame_half_size.y) * 0.5)
		for i in balloon.edge_offsets.size() - 1: # Ignore the closing point
			#First, add a point at the corner
			var point_in:Vector2 = tangent.rotated(balloon.rng.randf_range(-ANGLE, ANGLE)) * force
			tangent = tangent.rotated (-TAU * 0.25) # Go around the corner
			var point_out:Vector2 = tangent.rotated(balloon.rng.randf_range(-ANGLE, ANGLE)) * force
			tangent = tangent.rotated (TAU * -0.375) # Turn it into the normal
			curve.add_point(balloon.center_point + balloon.edge_offsets[i], point_in, point_out)
			tangent = tangent.rotated (TAU * -0.125) # Now into the in tangent of the next point
			if (balloon.frame_half_size.y > balloon.frame_half_size.x) == (i % 2 == 1): # Tests if we're on the longer edge 
				# Add a midpoint to the longest edge
				point_in = tangent.rotated(balloon.rng.randf_range(-ANGLE, ANGLE)) * force
				point_out = point_in.rotated(PI)
				curve.add_point(balloon.center_point + (balloon.edge_offsets[i] + balloon.edge_offsets[i + 1]) * 0.5, point_in, point_out)
				
			#Then add a point along the edge 
		curve.add_point(curve.get_point_position(0), curve.get_point_in(0), curve.get_point_out(0)) # Close the shape
		balloon.edge_points = curve.get_baked_points()
