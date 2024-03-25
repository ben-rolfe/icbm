class_name ComicBurstEdgeStyle
extends ComicFeaturedEdgeStyle

const FORCE:float = 4.8
const ANGLE:float = PI * 0.9
const SURGE:float = 0.2

func _init():
	super()
	id = "burst"
	editor_name = "Burst"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "edge_burst.svg"))
	tail_inset_multiplier = 1

func calculate_points(balloon:ComicBalloon):
	if balloon.edge_offsets.size() > 0:
		super(balloon) #Note: This stores the feature points in balloon.edge_points - we will use them then replace them with the proper edge_points
		# Prepare for the sub-curves
		var curve:Curve2D = Curve2D.new()
		curve.bake_interval = balloon.edge_segment_length
		for i in balloon.edge_points.size():
			var normal:Vector2 = (balloon.shape.get_edge_transform(balloon, balloon.edge_points[i].angle()).y + balloon.edge_points[i].normalized()).normalized()
			# For some extra irregularity, we pump up the force and push out every second point by between 0 and a bit.
			# We use i % 2 == 1, not 0, because we'd rather have two adjacent unsurged points than two adjacent surged points.
			var surge:float = balloon.rng.randf_range(1, 1 + SURGE) if i % 2 == 1 else 1.0
			var point_in:Vector2 = normal.rotated(-ANGLE) * FORCE * balloon.edge_segment_length * surge
			var point_out:Vector2 = normal.rotated(ANGLE) * FORCE * balloon.edge_segment_length * surge
			curve.add_point(balloon.center_point + balloon.edge_points[i] + normal * FORCE * balloon.edge_segment_length * surge, point_in, point_out)
		curve.add_point(curve.get_point_position(0), curve.get_point_in(0), curve.get_point_out(0)) # Close the shape
		balloon.edge_points = curve.get_baked_points()
