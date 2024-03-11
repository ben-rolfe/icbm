class_name ComicRoughTailStyle
extends ComicTailStyle

const SHIFT:float = 0.5
const FORCE:float = 0.5

func _init():
	id = "rough"
	editor_name = "Rough"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "tail_rough.svg"))
	is_randomized = true

func adjust_points(tail:ComicTail):
	for i in tail.edge_points.size() / 2:
		var j = tail.edge_points.size() - i - 1
		var off_mid_point = tail.edge_points[i].lerp(tail.edge_points[j], 0.5 + tail.rng.randf_range(-SHIFT, SHIFT))
		var w = tail.rng.randf_range(-FORCE, FORCE)
		tail.edge_points[i] += (tail.edge_points[i] - off_mid_point) * w
		tail.edge_points[j] += (tail.edge_points[j] - off_mid_point) * w
