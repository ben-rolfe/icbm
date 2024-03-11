class_name ComicZigTailStyle
extends ComicTailStyle

var shift:float = 16

func _init():
	id = "zig"
	editor_name = "Zig"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "tail_zig.svg"))

func get_base_curve(tail:ComicTail) -> Curve2D:
	var curve:Curve2D = super(tail)

	var split_point = (tail.p_start + tail.v_start + tail.p_end + tail.v_end) * 0.5	
	var offset_a = ((split_point - tail.p_start).rotated(TAU / 4).normalized() + (tail.v_start if shift > 0 else tail.v_end) / tail.p_end.distance_to(tail.p_start)) * shift
	var offset_b = ((split_point - tail.p_end).rotated(TAU / 4).normalized() + (tail.v_end if shift > 0 else tail.v_start) / tail.p_end.distance_to(tail.p_start)) * shift
	curve.add_point(split_point + offset_a, Vector2.ZERO, Vector2.ZERO, 1)
	curve.add_point(split_point + offset_b, Vector2.ZERO, Vector2.ZERO, 2)
	return curve	
