class_name ComicImageShape
extends ComicBoxShape

func _init():
	id = "image"
	editor_name = "Image"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "image.svg"))
	editor_show_edge_options = false
	editor_show_image_options = true

func has_point(balloon:ComicBalloon, global_point:Vector2) -> bool:
	if balloon.panel == null:
		return super(balloon, global_point)
	return balloon.panel.get_global_rect().has_point(global_point)

func manage_panel(balloon:ComicBalloon):
	if balloon.image == "":
		#No image selected - remove any panel
		if balloon.panel != null:
			balloon.panel.queue_free()
			balloon.panel = null
	else:
		if balloon.panel != null and not balloon.panel is NinePatchRect:
			# We've got a panel from somewhere else - maybe this just changed from being a different edge style - remove it.
			balloon.panel.queue_free()
			balloon.panel = null
			
		if balloon.panel == null:
			balloon.panel = NinePatchRect.new()
			balloon.add_child(balloon.panel)
			balloon.panel.show_behind_parent = true
		var img_path:String = str(Comic.DIR_IMAGES, balloon.image)
		if ResourceLoader.exists(img_path):
			balloon.panel.texture = ResourceLoader.load(img_path)

		var nine_slice:Vector4i = balloon.nine_slice
		var padding:Vector4 = balloon.padding
		
		balloon.panel.size = Vector2(balloon.bounds_rect.size.x + nine_slice.x + nine_slice.z + padding.x + padding.z, balloon.bounds_rect.size.y + nine_slice.y + nine_slice.w + padding.y + padding.w)
		balloon.panel.patch_margin_left = nine_slice.x
		balloon.panel.patch_margin_top = nine_slice.y
		balloon.panel.patch_margin_right = nine_slice.z
		balloon.panel.patch_margin_bottom = nine_slice.w
		# Half the difference between the size width and the bounds width is subtracted - this is to compensate for collapsed text boxes.
		balloon.panel.position = Vector2((balloon.size.x - balloon.bounds_rect.size.x) * 0.5 - (padding.x + nine_slice.x), -(padding.y + nine_slice.y))
		balloon.panel.self_modulate = balloon.fill_color
		
func get_edge_offset(balloon:ComicBalloon, angle:float) -> Vector2:
	angle = fposmod(angle, TAU)
	var corner_angles = Vector4(
		fposmod(Vector2(balloon.frame_half_size.x + balloon.padding.z + balloon.nine_slice.z, balloon.frame_half_size.y + balloon.padding.w + balloon.nine_slice.w).angle(), TAU),
		fposmod(Vector2(-balloon.frame_half_size.x - balloon.padding.x - balloon.nine_slice.x, balloon.frame_half_size.y + balloon.padding.w + balloon.nine_slice.w).angle(), TAU),
		fposmod(Vector2(-balloon.frame_half_size.x - balloon.padding.x - balloon.nine_slice.x, -balloon.frame_half_size.y - balloon.padding.y - balloon.nine_slice.y).angle(), TAU),
		fposmod(Vector2(balloon.frame_half_size.x + balloon.padding.z + balloon.nine_slice.z, -balloon.frame_half_size.y - balloon.padding.y - balloon.nine_slice.y).angle(), TAU)
	)
	if angle < corner_angles[0] or angle > corner_angles[3]:
		# on right side
		var x = balloon.frame_half_size.x + balloon.padding.z + balloon.nine_slice.z
		return Vector2(x, x * tan(angle))
	elif angle < corner_angles[1]:
		# on bottom
		var y = balloon.frame_half_size.y + balloon.padding.w + balloon.nine_slice.w
		return Vector2(y / tan(angle), y)
	elif angle < corner_angles[2]:
		# on left side
		var x = -balloon.frame_half_size.x - balloon.padding.x - balloon.nine_slice.x
		return Vector2(x, x * tan(angle))
	else:
		# on top
		var y = -balloon.frame_half_size.y - balloon.padding.y - balloon.nine_slice.y
		return Vector2(y / tan(angle), y)

func get_edge_transform(balloon:ComicBalloon, angle:float) -> Transform2D:
	angle = fposmod(angle, TAU)
	var offset:Vector2 = get_edge_offset(balloon, angle)
	var tangent_angle:float
	if offset.x > balloon.frame_half_size.x + balloon.padding.z + balloon.nine_slice.z - balloon.tail_width * 0.5:
		# right edge or corner
		if offset.y > balloon.frame_half_size.y + balloon.padding.w + balloon.nine_slice.w - balloon.tail_width * 0.5:
			# bottom-right corner
			tangent_angle = TAU * 0.875
		elif offset.y < balloon.tail_width * 0.5 - balloon.frame_half_size.y - balloon.padding.y - balloon.nine_slice.y:
			# top-right corner
			tangent_angle = TAU * 0.625
		else:
			# right edge
			tangent_angle = TAU * 0.75
	elif offset.x < balloon.tail_width * 0.5 - balloon.frame_half_size.x - balloon.padding.x - balloon.nine_slice.x:
		# left edge or corner
		if offset.y > balloon.frame_half_size.y + balloon.padding.w + balloon.nine_slice.w - balloon.tail_width * 0.5:
			# bottom-left corner
			tangent_angle = TAU * 0.125
		elif offset.y < balloon.tail_width * 0.5 - balloon.frame_half_size.y - balloon.padding.y - balloon.nine_slice.y:
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
