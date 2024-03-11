class_name ComicCloudEdgeStyle
extends ComicFeaturedEdgeStyle

const FORCE:float = 3
const ANGLE:float = PI * 0.3
const SURGE:float = -PI * 0.2
const INSET:float = 0.2

func _init():
	super()
	id = "cloud"
	editor_name = "Cloud"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "edge_cloud.svg"))
	tail_inset_multiplier = 1
	tail_style_id = "cloud"

func calculate_points(balloon:ComicBalloon):
	if balloon.edge_offsets.size() > 0:
		super(balloon) #Note: This stores the feature points in balloon.edge_points - we will use them then replace them with the proper edge_points
		# Prepare for the sub-curves
		var curve:Curve2D = Curve2D.new()
		curve.bake_interval = balloon.edge_segment_length
		var edge_normals:Array[Vector2] = []
		for i in balloon.edge_points.size():
			edge_normals.push_back(balloon.shape.get_edge_transform(balloon, balloon.edge_points[i].angle()).y)
		var angle:float = ANGLE
		for i in balloon.edge_points.size():
			# Our angular corrections are values between 1, if both points are pointing in the same direction, to 3, if they're pointing in opposite directions
			var angular_correction_in = 1 + min(abs(edge_normals[i - 1].angle_to(edge_normals[i])) * 2 / TAU, 1) * 2
			var angular_correction_out = 1 + min(abs(edge_normals[i].angle_to(edge_normals[i + 1 - edge_normals.size()])) * 2 / TAU, 1) * 2

			var point_in:Vector2 = edge_normals[i].rotated(-angle) * FORCE * balloon.edge_segment_length * angular_correction_in
			#Note that we change the angle value BETWEEN points, so that the surge of the out handle of one point will match the surge of the in value of the next
			angle = balloon.rng.randf_range(ANGLE, ANGLE + SURGE) if i % 2 == 1 else ANGLE
			var point_out:Vector2 = edge_normals[i].rotated(angle) * FORCE * balloon.edge_segment_length * angular_correction_out

			curve.add_point(balloon.center_point + balloon.edge_points[i] - edge_normals[i] * INSET * FORCE * balloon.edge_segment_length, point_in, point_out)
		curve.add_point(curve.get_point_position(0), curve.get_point_in(0), curve.get_point_out(0)) # Close the shape
		balloon.edge_points = curve.get_baked_points()

