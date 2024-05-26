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
	serves.width = Comic.book.snap(abs(global_position.x - serves.anchor.x)) * (2 if is_equal_approx(serves.anchor_to.x, 0.5) else 1)
	serves.rebuild(true)
	Comic.book.page.redraw()

func add_menu_items(menu:PopupMenu):	
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "undo.svg")), "Reset to Default Width", ComicEditor.MenuCommand.DEFAULT)
	if serves.is_default("width"):
		menu.set_item_disabled(-1, true)

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DEFAULT:
			Comic.book.add_undo_step([ComicReversionData.new(serves)])
			serves.clear_data("width")
			serves.rebuild(true)
			Comic.book.page.rebuild_widgets()
		ComicEditor.MenuCommand.DELETE:
			Comic.book.add_undo_step([ComicReversionData.new(serves)])
			serves.collapse = true
			serves.width = 0
			serves.rebuild(true)
			Comic.book.page.rebuild_widgets()
		ComicEditor.MenuCommand.TOGGLE_COLLAPSE:
			Comic.book.add_undo_step([ComicReversionData.new(serves)])
			serves.collapse = !serves.collapse
			if serves.width == 0 and not serves.collapse:
				serves.clear_data("width")
			serves.rebuild(true)

