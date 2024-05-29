class_name ComicLinePointWidget
extends ComicWidget

var index:int

func _init(serves:CanvasItem, index:int): # Serves can be either a ComicLine or ComicHotspot
	self.index = index
	action = ComicWidget.Action.MOVE
	super(serves)
	color = Color.PURPLE
	name = "Line Point"

func reposition():
	anchor = serves.points[index] + serves.anchor

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(serves)])
	super(at_position)

func dragged(global_position:Vector2):
	if index > 0:
		serves.points[index] = Comic.book.snap_and_contain(global_position) - serves.anchor
	else:
		var diff:Vector2 = Comic.book.snap_and_contain(global_position) - serves.anchor
		for i in range(1, serves.points.size()):
			serves.points[i] -= diff
		serves.anchor += diff
	Comic.book.page.redraw()
	
func dropped(global_position:Vector2):
	super(global_position)
	serves.rebuild()

func add_menu_items(menu:PopupMenu):
	if serves is ComicLine:
		if serves.points.size() > 2:
			menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "remove_line_point.svg")), "Remove Point", ComicEditor.MenuCommand.DELETE_PART)
		else:
			menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Remove Line", ComicEditor.MenuCommand.DELETE)
	else: # Hotspot
		if serves.points.size() > 3:
			menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "remove_line_point.svg")), "Remove Point", ComicEditor.MenuCommand.DELETE_PART)
		menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "anchor_tl.svg")), "Set as Anchor", ComicEditor.MenuCommand.MOVE_TO_TOP)

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
		ComicEditor.MenuCommand.MOVE_TO_TOP:
			for i in range(index):
				serves.points.push_back(serves.points.pop_front())
			serves.anchor += serves.points[0]
			for i in range(serves.points.size() - 1, -1, -1):
				serves.points[i] -= serves.points[0]
			Comic.book.page.redraw(true)
			Comic.book.page.rebuild_widgets()
