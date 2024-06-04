class_name ComicRotateWidget
extends ComicWidget

func _init(serves:Control):
	action = ComicWidget.Action.TURN
	super(serves)
	color = Color.RED
	name = "Rotate"

func draw_connector(layer):
	pass

func reposition():
	anchor = serves.anchor + Vector2(
		0,
		serves.size.y * (1 if is_zero_approx(serves.anchor_to.y) else -1 if is_equal_approx(serves.anchor_to.y, 1.0) else 0.5)
	).rotated(serves.rotate)
	#if is_equal_approx(serves.anchor_to.x, 1):
		#anchor = serves.center_point - Vector2(serves.size.x * 0.5, 0)
	#else:
		#anchor = serves.center_point + Vector2(serves.size.x * 0.5, 0)

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(serves)])
	super(at_position)

func dragged(global_position:Vector2):
	serves.rotate = (serves.anchor - global_position).angle() + (-TAU/4 if is_equal_approx(serves.anchor_to.y, 1.0) else TAU/4)
	serves.rebuild(true)
	Comic.book.page.redraw()

func add_menu_items(menu:PopupMenu):	
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "undo.svg")), "Clear rotation", ComicEditor.MenuCommand.DEFAULT)
	if serves.is_default("rotate"):
		menu.set_item_disabled(-1, true)

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DEFAULT:
			Comic.book.add_undo_step([ComicReversionData.new(serves)])
			serves.clear_data("rotate")
			serves.rebuild(true)
			Comic.book.page.rebuild_widgets()
