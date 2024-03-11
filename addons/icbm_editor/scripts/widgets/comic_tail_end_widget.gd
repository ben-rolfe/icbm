class_name ComicTailEndWidget
extends ComicTailStartWidget


func _init(serves:ComicTail):
	v_id = "v_end"
	p_id = "p_end"
	super(serves)
	name = "Tail End"

func dragged(global_position:Vector2):
	if serves.data.linked:
		serves.data.end_placement_angle = (global_position - serves.end_balloon.center_point).angle()
	else:
		serves.data.p_end = Comic.book.snap(global_position)
	serves.balloon.rebuild_tail(serves.oid)
	Comic.book.page.redraw()

func dropped(global_position:Vector2):
	if serves.data.linked:
		super(global_position)
	else:
		var balloon:ComicBalloon = Comic.book.page.get_o_at_point(global_position, ComicBalloon, serves.balloon)
		if balloon == null:
			super(global_position)
		else:
			serves.attach_end(balloon, serves.v_end.angle())
