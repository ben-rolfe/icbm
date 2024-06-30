class_name ComicBoxShape
extends ComicShape

func _init():
	id = "box"
	editor_name = "Box"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "shape_box.svg"))

func adjust_frame_half_size(_balloon:ComicBalloon):
	pass

func get_edge_transform(balloon:ComicBalloon, angle:float) -> Transform2D:
	angle = fposmod(angle, TAU)
	var offset:Vector2 = get_edge_offset(balloon, angle)
	var tangent_angle:float
	if offset.x > balloon.frame_half_size.x + balloon.padding.z - balloon.tail_width * 0.5:
		# right edge or corner
		if offset.y > balloon.frame_half_size.y + balloon.padding.w - balloon.tail_width * 0.5:
			# bottom-right corner
			tangent_angle = TAU * 0.875
		elif offset.y < balloon.tail_width * 0.5 - balloon.frame_half_size.y - balloon.padding.y:
			# top-right corner
			tangent_angle = TAU * 0.625
		else:
			# right edge
			tangent_angle = TAU * 0.75
	elif offset.x < balloon.tail_width * 0.5 - balloon.frame_half_size.x - balloon.padding.x:
		# left edge or corner
		if offset.y > balloon.frame_half_size.y + balloon.padding.w - balloon.tail_width * 0.5:
			# bottom-left corner
			tangent_angle = TAU * 0.125
		elif offset.y < balloon.tail_width * 0.5 - balloon.frame_half_size.y - balloon.padding.y:
			# top-left corner
			tangent_angle = TAU * 0.375
		else:
			# left edge
			tangent_angle = TAU * 0.25
	elif offset.y > 0:
		# bottom edge
		tangent_angle = 0
	else:
		# top edge
		tangent_angle = TAU * 0.5
	return Transform2D(tangent_angle, offset)

func get_edge_offset(balloon:ComicBalloon, angle:float) -> Vector2:
	angle = fposmod(angle, TAU)
	var corner_angles = Vector4(
		fposmod(Vector2(balloon.frame_half_size.x + balloon.padding.z, balloon.frame_half_size.y + balloon.padding.w).angle(), TAU),
		fposmod(Vector2(-balloon.frame_half_size.x - balloon.padding.x, balloon.frame_half_size.y + balloon.padding.w).angle(), TAU),
		fposmod(Vector2(-balloon.frame_half_size.x - balloon.padding.x, -balloon.frame_half_size.y - balloon.padding.y).angle(), TAU),
		fposmod(Vector2(balloon.frame_half_size.x + balloon.padding.z, -balloon.frame_half_size.y - balloon.padding.y).angle(), TAU)
	)
	if angle < corner_angles[0] or angle > corner_angles[3]:
		# on right side
		var x = balloon.frame_half_size.x + balloon.padding.z
		return Vector2(x, x * tan(angle))
	elif angle < corner_angles[1]:
		# on bottom
		var y = balloon.frame_half_size.y + balloon.padding.w
		return Vector2(y / tan(angle), y)
	elif angle < corner_angles[2]:
		# on left side
		var x = -balloon.frame_half_size.x - balloon.padding.x
		return Vector2(x, x * tan(angle))
	else:
		# on top
		var y = -balloon.frame_half_size.y - balloon.padding.y
		return Vector2(y / tan(angle), y)

func has_point(balloon:ComicBalloon, global_point:Vector2) -> bool:
	return balloon.bounds_rect.has_point(global_point)


