class_name ComicMoveWidget
extends ComicWidget

func _init(serves:Control):
	action = ComicWidget.Action.MOVE
	super(serves)
	color = Color.RED
	name = "Move"

func reposition():
	anchor = serves.anchor

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(serves)])
	super(at_position)

func dragged(global_position:Vector2):
	serves.anchor = Comic.book.snap(global_position)
	serves.rebuild(true)
	Comic.book.page.redraw()
