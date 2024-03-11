class_name ComicOpenTailTip
extends ComicTailTip

func _init():
	id = "open"
	editor_name = "Open"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "tail_open.svg"))

func calculate_points(tail:ComicTail, transforms:Array[Transform2D]):
	var points:Array[Vector2] = []
	for i in transforms.size():
		#Squeeze the width in the middle
		var squeeze = 0.5 - i / float(transforms.size() - 1)
		squeeze = squeeze * squeeze + 0.75
		var w:float = Comic.tail_width * 0.5 * squeeze
		points.push_front(transforms[i].origin + transforms[i].y * w)
		points.push_back(transforms[i].origin - transforms[i].y * w)
	tail.edge_points = points
