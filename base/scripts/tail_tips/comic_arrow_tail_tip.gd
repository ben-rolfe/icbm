class_name ComicArrowTailTip
extends ComicOpenTailTip

const LENGTH:int = 5
const WIDTH:float = 2.4

func _init():
	id = "arrow"
	editor_name = "Arrow"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "tail_arrow.svg"))

func calculate_points(tail:ComicTail, transforms:Array[Transform2D]):
	super(tail, transforms)
	
	# Calculate the length of the arrow
	var old_length:float
	var new_length:float
	var last_center:Vector2
	for i in LENGTH + 1:
		var j:int = tail.edge_points.size() - 1 - i
		var center = (tail.edge_points[i] + tail.edge_points[j]) * 0.5
		if i > 0:
			if i < LENGTH:
				old_length += center.distance_to(last_center)
			else:
				new_length = old_length + center.distance_to(last_center)
		last_center = center
	
	# Adjust the points
	var d:float = 0
	for i in LENGTH:
		var j:int = tail.edge_points.size() - 1 - i
		var center = (tail.edge_points[i] + tail.edge_points[j]) * 0.5
		if i > 0:
			d += center.distance_to(last_center)
			# Widen (or narrow) the points
			tail.edge_points[i] = center + (tail.edge_points[i] - center).normalized() * WIDTH * Comic.tail_width * 0.5 * d / old_length
			tail.edge_points[j] = center + (tail.edge_points[j] - center).normalized() * WIDTH * Comic.tail_width * 0.5 * d / old_length
			# Elongate the points
			tail.edge_points[i] += (tail.edge_points[0] - tail.edge_points[i]) * (1 - new_length / old_length)
			tail.edge_points[j] += (tail.edge_points[0] - tail.edge_points[j]) * (1 - new_length / old_length)
		else:
			tail.edge_points[i] = center
			tail.edge_points[j] = center
		last_center = center

	for i in 2:
		print(tail.edge_points[i])
