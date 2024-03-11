class_name ComicWobbleTailStyle
extends ComicTailStyle

const SPACING:int = 6
const FORCE:float = SPACING / 2.0

func _init():
	id = "wobble"
	editor_name = "Wobble"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "tail_wobble.svg"))
	is_randomized = true

func get_spine_points(tail:ComicTail) -> Array[Transform2D]:
	var curve:Curve2D = get_base_curve(tail)
	# Add some wobble to the curve
	var new_curve:Curve2D = Curve2D.new()
	new_curve.add_point(tail.p_start + tail.inset_start, Vector2.ZERO, tail.v_start.normalized() * 2)
	var baked_length:float = curve.get_baked_length()
	var n:int = floori(baked_length / Comic.EDGE_SEGMENT_LENGTH)
	var i = 0
	while i + SPACING * 3 < n:
		i += tail.rng.randi_range(SPACING, SPACING * 2)
		var t = float(i) / n
		var side_shift_multiplier:float = Comic.EDGE_SEGMENT_LENGTH * 0.5
		var extra_point:Transform2D = curve.sample_baked_with_rotation(baked_length * t, true)
		new_curve.add_point(extra_point.origin + extra_point.x * side_shift_multiplier * tail.rng.randf_range(-SPACING, SPACING), extra_point.y * side_shift_multiplier * -tail.rng.randf_range(FORCE, FORCE * 2), extra_point.y * side_shift_multiplier * tail.rng.randf_range(FORCE, FORCE * 2))
	new_curve.add_point(tail.p_end + tail.inset_end, tail.v_end.normalized() * 2, Vector2.ZERO)
	curve = new_curve
	
	return points_to_transforms(curve.get_baked_points())
