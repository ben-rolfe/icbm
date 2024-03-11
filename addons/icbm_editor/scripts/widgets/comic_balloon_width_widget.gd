class_name ComicBalloonWidthWidget
extends ComicWidget

func _init(serves:ComicBalloon):
	action = ComicWidget.Action.MOVE
	super(serves)
	color = Color.RED
	name = "Width"

func reposition():
	if is_equal_approx(serves.anchor_to.x, 1):
		anchor = serves.center_point - Vector2(serves.size.x * 0.5, 0)
	else:
		anchor = serves.center_point + Vector2(serves.size.x * 0.5, 0)

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(serves)])
	super(at_position)

func dragged(global_position:Vector2):
	serves.data.width = Comic.book.snap(abs(global_position.x - serves.center_point.x))
	if is_equal_approx(serves.data.get("offset_to", Vector2(0.5,0.5)).x, 0.5):
		serves.data.width *= 2
	serves.rebuild(true)
	Comic.book.page.redraw()

func add_menu_items(menu:PopupMenu):	
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "undo.svg")), "Reset to Default Width", ComicEditor.MenuCommand.DEFAULT)
	if not serves.data.has("width"):
		menu.set_item_disabled(-1, true)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Clear Fixed Width", ComicEditor.MenuCommand.DELETE)

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
