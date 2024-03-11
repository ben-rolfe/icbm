class_name ComicBurstBoxEdgeStyle
extends ComicBoxEdgeStyle

const FORCE = 4
const ANGLE = PI * 0.9

func _init():
	super()
	id = "burst"
	editor_name = "Burst"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "edge_burst_box.svg"))

func calculate_points(balloon:ComicBalloon):
	if balloon.edge_offsets.size() > 0:
		# Prepare for the sub-curves
		var curve:Curve2D = Curve2D.new()
		curve.bake_interval = balloon.edge_segment_length
		var normal = Vector2.from_angle(TAU * 0.375)
		for i in balloon.edge_offsets.size() - 1: # Ignore the closing point
			normal = normal.rotated(TAU * 0.25)
			var point_in:Vector2 = normal.rotated(-ANGLE) * FORCE * balloon.edge_segment_length
			var point_out:Vector2 = normal.rotated(ANGLE) * FORCE * balloon.edge_segment_length
			curve.add_point(balloon.center_point + balloon.edge_offsets[i] + normal * FORCE * balloon.edge_segment_length, point_in, point_out)
		curve.add_point(curve.get_point_position(0), curve.get_point_in(0), curve.get_point_out(0)) # Close the shape
		balloon.edge_points = curve.get_baked_points()


		#for i in feature_offsets.size():
			#var point_in:Vector2 = feature_normals[i].rotated(PI * -0.9) * _edge_style_force * 2 * edge_segment_length
			#var point_out:Vector2 = feature_normals[i].rotated(PI * 0.9) * _edge_style_force * 2 * edge_segment_length
			#curve.add_point(center_point + feature_offsets[i] + feature_normals[i] * _edge_style_force * edge_segment_length, point_in, point_out)
