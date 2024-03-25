class_name ComicCloudBoxEdgeStyle
extends ComicBoxEdgeStyle

func _init():
	super()
	id = "cloud"
	editor_name = "Cloud"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "edge_cloud_box.svg"))
	tail_style_id = "cloud"

func calculate_points(balloon:ComicBalloon):
	if balloon.edge_offsets.size() > 0:
		# Prepare for the sub-curves
		var curve:Curve2D = Curve2D.new()
		curve.bake_interval = balloon.edge_segment_length
		for i in balloon.edge_offsets.size() - 1: # Ignore the closing point
			var point_out:Vector2 = balloon.edge_offsets[i + 1] * 0.1
			var point_in:Vector2 = -point_out
			curve.add_point(balloon.center_point + balloon.edge_offsets[i], point_in, point_out)
		curve.add_point(curve.get_point_position(0), curve.get_point_in(0), curve.get_point_out(0)) # Close the shape
		balloon.edge_points = curve.get_baked_points()
