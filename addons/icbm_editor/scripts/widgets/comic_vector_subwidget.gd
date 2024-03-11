class_name ComicVectorSubwidget
extends ComicWidget

var property_name = ""

func _init(serves:Object):
	action = ComicWidget.Action.TURN
	super(serves)
	color = Color.ORANGE

func reposition():
	anchor = serves.anchor + serves.custom_vector

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(serves.serves.balloon)])
	super(at_position)

func dragged(global_position:Vector2):
	serves.custom_vector = global_position - serves.anchor

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Remove Handle", ComicEditor.MenuCommand.DELETE)

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DELETE:
			Comic.book.add_undo_step([ComicReversionData.new(serves.serves.balloon)])
			serves.has_custom_vector = not serves.has_custom_vector

