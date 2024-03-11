class_name ComicSquinkTailTip
extends ComicOpenTailTip

const MIN_POINTS:int = 5
const MAX_POINTS:int = 7
const MIN_LENGTH:float = 5
const MAX_LENGTH:float = 8

func _init():
	id = "squink"
	editor_name = "Squink"
	editor_icon = load(str(ComicEditor.DIR_ICONS, "tail_squink.svg"))
	is_randomized = true

func calculate_points(tail:ComicTail, transforms:Array[Transform2D]):
	super(tail, transforms)
	
	# Create the squink
	var curve:Curve2D = Curve2D.new()
	curve.bake_interval = Comic.EDGE_SEGMENT_LENGTH
	var angle = tail.rng.randf_range(0, TAU)
	var points = tail.rng.randi_range(MIN_POINTS, MAX_POINTS)
	var angle_step = TAU / points
	for i in points:
		angle += angle_step
		var v:Vector2 = Vector2.from_angle(angle + angle_step * 0.25 * tail.rng.randf_range(-1, 1)) * Comic.EDGE_SEGMENT_LENGTH * tail.rng.randf_range(MIN_LENGTH, MAX_LENGTH)
		curve.add_point(tail.p_end + v, v.rotated(PI * -0.9) / points * 2, v.rotated(PI * 0.9) / points * 2)
	curve.add_point(curve.get_point_position(0), curve.get_point_in(0), curve.get_point_out(0))
		
	tail.under_points = curve.get_baked_points()
