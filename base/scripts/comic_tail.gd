class_name ComicTail
extends RefCounted

var oid:int
# We can't store the balloon itself as that would create a cyclic reference.
var balloon_oid:int

var edge_points:PackedVector2Array
var under_points:PackedVector2Array # For things like squinks
var edge_color_start:Color
var edge_color_end:Color
var edge_thickness:float
var end_balloon:ComicBalloon
var fill_color_start:Color
var fill_color_end:Color
var p_end:Vector2
var p_start:Vector2
var rng:RandomNumberGenerator
var style:ComicTailStyle
var tip:ComicTailTip
var v_end:Vector2
var v_start:Vector2
var inset_start:Vector2
var inset_end:Vector2

# We don't store the balloon, to avoid circular references. Instead, we store its oid.
var balloon:ComicBalloon:
	get:
		return Comic.book.page.os[balloon_oid]
	set(value):
		balloon_oid = value.oid

var data:Dictionary:
	get:
		return balloon.tail_data[oid]

func _init(_oid: int, _balloon:ComicBalloon):
	oid = _oid
	balloon = _balloon
	if not data.has("rng_seed"):
		data.rng_seed = balloon.rng_seed + balloon.tails.size()
	if not data.has("start_placement_angle"):
		data.start_placement_angle = TAU / 4
	if not data.has("linked"):
		data.linked = false
	if not data.linked and not data.has("p_end"):
		data.p_end = ComicEditor.snap(balloon.center_point + balloon.shape.get_edge_transform(balloon, TAU / 4).origin + Vector2.DOWN * 5 * Comic.px_per_unit)

func apply_data():
	style = Comic.get_tail_style(data.get("style", balloon.edge_style.tail_style_id))
	tip = Comic.get_tail_tip(data.get("tip", "open" if data.linked else "point"))

	if style.is_randomized or tip.is_randomized:
		rng = RandomNumberGenerator.new()
		rng.seed = data.rng_seed

	#TODO: Think about getting fancy and blending to the end balloon values.
	edge_color_start = balloon.edge_color
	edge_thickness = balloon.edge_thickness
	fill_color_start = balloon.fill_color

	# Calculate start and end points
	var t_start:Transform2D = balloon.shape.get_edge_transform(balloon, data.start_placement_angle)
	# We inset the balloon by half the tail width, and by a chunk more for burst and cloud balloons, whose edges can randomly push into the balloon quite a lot.
	inset_start = -t_start.y * (Comic.tail_width * 0.5 + Comic.EDGE_SEGMENT_LENGTH * data.get("inset_start_multiplier", balloon.edge_style.tail_inset_multiplier))
	p_start = t_start.origin + balloon.center_point
	var t_end:Transform2D
	if data.linked:
		end_balloon = Comic.book.page.os[data.end_oid]
		t_end = end_balloon.shape.get_edge_transform(end_balloon, data.end_placement_angle)
		inset_end = -t_end.y * (Comic.tail_width * 0.5 + Comic.EDGE_SEGMENT_LENGTH * data.get("inset_end_multiplier", end_balloon.edge_style.tail_inset_multiplier))
		p_end = t_end.origin + end_balloon.center_point
		edge_color_end = end_balloon.edge_color
		fill_color_end = end_balloon.fill_color
	else:
		p_end = data.p_end
		inset_end = Vector2.ZERO
		edge_color_end = edge_color_start
		fill_color_end = fill_color_start

	# Calculate start and end vectors
	var default_vector_length = p_start.distance_to(p_end) / 3.0
	v_start = data.get("v_start", Vector2.INF)
	v_end = data.get("v_end", Vector2.INF)
	if v_start == Vector2.INF:
		v_start = t_start.y * default_vector_length
	if v_end == Vector2.INF:
		if data.linked:
			v_end = t_end.y * default_vector_length
		else:
			v_end = (p_start + v_start - p_end).normalized() * default_vector_length

	# Create the curve
	edge_points = PackedVector2Array()
	under_points = PackedVector2Array()
	if style.supports_tips:
		tip.calculate_points(self, style.get_spine_points(self))
	style.adjust_points(self)

func rebuild(_rebuild_subobjects:bool):
	apply_data()
	Comic.book.page.redraw()

func draw_edge(draw_layer:ComicLayer):
	style.draw_under(self, draw_layer)
	style.draw_edge(self, draw_layer)

func draw_fill(draw_layer:ComicLayer):
	style.draw_fill(self, draw_layer)

# ------------------------------------------------------------------------------
# Editor Methods - TODO: subclass?
# ------------------------------------------------------------------------------

func attach_end(_end_balloon:ComicBalloon, end_placement_angle:float):
	# Note that we don't create an undo point, since this action is the result of a drag action, and an undo point was created at the start of the drag
	data.linked = true
	data.end_oid = _end_balloon.data.oid
	data.end_placement_angle = end_placement_angle
	# (balloon.center_point - end_balloon.center_point).angle()
	balloon.rebuild_tails()
	Comic.book.page.redraw(true)
