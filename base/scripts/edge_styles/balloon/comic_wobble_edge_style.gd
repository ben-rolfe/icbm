class_name ComicWobbleEdgeStyle
extends ComicFeaturedEdgeStyle

const FORCE:float = 4
const ANGLE:float = PI * 0.9
const SURGE:float = 0.2

func _init():
	super()
	id = "wobble"
	editor_name = "Wobble"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "edge_wobble.svg"))
	tail_inset_multiplier = 2
	tail_style_id = "wobble"

func calculate_points(balloon:ComicBalloon):
	if balloon.edge_offsets.size() > 0:
		super(balloon) #Note: This stores the feature points in balloon.edge_points - we will use them then replace them with the proper edge_points
		# Prepare for the sub-curves
		var curve:Curve2D = Curve2D.new()
		curve.bake_interval = balloon.edge_segment_length
		for i in balloon.edge_points.size():
			var normal:Vector2 = (balloon.shape.get_edge_transform(balloon, balloon.edge_points[i].angle()).y + balloon.edge_points[i].normalized()).normalized()
			var point_in:Vector2 = normal.rotated(-TAU / 4) * FORCE * balloon.edge_segment_length
			var point_out:Vector2 = normal.rotated(TAU / 4) * FORCE * balloon.edge_segment_length
			curve.add_point(balloon.center_point + balloon.edge_points[i], point_in, point_out)
		curve.add_point(curve.get_point_position(0), curve.get_point_in(0), curve.get_point_out(0)) # Close the shape
		balloon.edge_points = curve.get_baked_points()


