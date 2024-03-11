class_name ComicBoxShape
extends ComicShape

func _init():
	id = "box"
	editor_name = "Box"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "shape_box.svg"))
	center_adjustment = Vector2(Comic.theme.get_constant("box_margin_x", "Balloon"), Comic.theme.get_constant("box_margin_y", "Balloon"))

func adjust_frame_half_size(balloon:ComicBalloon):
	# For box shapes we add a margin, since the shape itself doesn't include any (unlike rounded shapes)
	balloon.frame_half_size += center_adjustment

func get_edge_transform(balloon:ComicBalloon, angle:float) -> Transform2D:
	angle = fposmod(angle, TAU)
	var offset:Vector2 = get_edge_offset(balloon, angle)
	var tangent_angle:float
	if offset.x > balloon.frame_half_size.x - Comic.tail_width * 0.5:
		# right edge or corner
		if offset.y > balloon.frame_half_size.y - Comic.tail_width * 0.5:
			# bottom-right corner
			tangent_angle = TAU * 0.875
		elif offset.y < Comic.tail_width * 0.5 - balloon.frame_half_size.y:
			# top-right corner
			tangent_angle = TAU * 0.625
		else:
			# right edge
			tangent_angle = TAU * 0.75
	elif offset.x < Comic.tail_width * 0.5 - balloon.frame_half_size.x:
		# left edge or corner
		if offset.y > balloon.frame_half_size.y - Comic.tail_width * 0.5:
			# bottom-left corner
			tangent_angle = TAU * 0.125
		elif offset.y < Comic.tail_width * 0.5 - balloon.frame_half_size.y:
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
	var first_corner_angle = fposmod(balloon.frame_half_size.angle(), TAU)
	if angle < first_corner_angle or angle > TAU - first_corner_angle:
		# on right side
		return Vector2(balloon.frame_half_size.x, balloon.frame_half_size.x * tan(angle))
	elif angle < PI - first_corner_angle:
		# on bottom
		return Vector2(balloon.frame_half_size.y / tan(angle), balloon.frame_half_size.y)
	elif angle < PI + first_corner_angle:
		# on left side
		return Vector2(-balloon.frame_half_size.x, -balloon.frame_half_size.x * tan(angle))
	else:
		# on top
		return Vector2(-balloon.frame_half_size.y / tan(angle), -balloon.frame_half_size.y)

func has_point(balloon:ComicBalloon, global_point:Vector2) -> bool:
	return balloon.bounds_rect.has_point(global_point)


