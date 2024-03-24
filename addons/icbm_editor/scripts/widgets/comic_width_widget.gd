class_name ComicWidthWidget
extends ComicWidget

func _init(serves:Control):
	action = ComicWidget.Action.SLIDE_H
	super(serves)
	color = Color.RED
	name = "Width"

func draw_connector(layer):
	pass

func reposition():
	if is_zero_approx(serves.anchor_to.x):
		anchor = serves.anchor + Vector2(serves.size.x, 0)
	elif is_equal_approx(serves.anchor_to.x, 1.0):
		anchor = serves.anchor - Vector2(serves.size.x, 0)
	else:
		anchor = serves.anchor + Vector2(serves.size.x * 0.5, 0)

	#if is_equal_approx(serves.anchor_to.x, 1):
		#anchor = serves.center_point - Vector2(serves.size.x * 0.5, 0)
	#else:
		#anchor = serves.center_point + Vector2(serves.size.x * 0.5, 0)

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(serves)])
	super(at_position)

func dragged(global_position:Vector2):
	serves.width = Comic.book.snap(abs(global_position.x - serves.anchor.x))
	serves.rebuild(true)
	Comic.book.page.redraw()

func add_menu_items(menu:PopupMenu):	
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "undo.svg")), "Reset to Default Width", ComicEditor.MenuCommand.DEFAULT)
	if not serves.data.has("width"):
		menu.set_item_disabled(-1, true)

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DEFAULT:
			Comic.book.add_undo_step([ComicReversionData.new(serves)])
			serves.data.erase("width")
			serves.rebuild(true)
			Comic.book.page.rebuild_widgets()
		ComicEditor.MenuCommand.DELETE:
			Comic.book.add_undo_step([ComicReversionData.new(serves)])
			serves.data.width = 0
			serves.rebuild(true)
			Comic.book.page.rebuild_widgets()
