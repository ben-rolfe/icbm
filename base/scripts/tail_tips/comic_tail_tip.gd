class_name ComicTailTip
extends RefCounted

var id:String = "point"
var editor_name:String = "Point"
var editor_icon:Texture2D = load(str(ComicEditor.DIR_ICONS, "tail_point.svg"))
var is_randomized:bool
var segment_divisor:int = 1

func calculate_points(tail:ComicTail, transforms:Array[Transform2D]):
	#TODO: Honestly, this would be so much better if draw_poly_line would accept a width array. Maybe I should get into the source code??
	# The draw methods require packedvector2array, but we want to populate the array by pushing at both back and front, which the packed arrays don't allow, so we start with an array and convert later.
	var points:Array[Vector2] = []
	for i in transforms.size():
		var w:float = Comic.tail_width * 0.5
		# Taper the width to a point
		w *= 1 - i / float(transforms.size() - 1)
		points.push_front(transforms[i].origin + transforms[i].y * w)
		points.push_back(transforms[i].origin - transforms[i].y * w)
	tail.edge_points = points
