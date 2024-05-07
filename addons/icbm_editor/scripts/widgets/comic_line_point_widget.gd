class_name ComicLinePointWidget
extends ComicWidget

var index:int

func _init(serves:ComicLine, index:int):
	self.index = index
	action = ComicWidget.Action.MOVE
	super(serves)
	color = Color.PURPLE
	name = "Line Point"

func reposition():
	anchor = serves.points[index]

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(serves)])
	super(at_position)

func dragged(global_position:Vector2):
	serves.points[index] = Comic.book.snap_and_contain(global_position)
	Comic.book.page.redraw()

func add_menu_items(menu:PopupMenu):
	if serves.points.size() > 2:
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "remove_line_point.svg")), "Remove Point", ComicEditor.MenuCommand.DELETE_PART)
	else:
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Remove Line", ComicEditor.MenuCommand.DELETE)

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DELETE:
			serves.remove()
			Comic.book.selected_element = null
			Comic.book.page.redraw(true)
			Comic.book.page.rebuild_widgets()
		ComicEditor.MenuCommand.DELETE_PART:
			Comic.book.add_undo_step([ComicReversionData.new(serves)])
			serves.points.pop_at(index)
			Comic.book.page.redraw(true)
			Comic.book.page.rebuild_widgets()
