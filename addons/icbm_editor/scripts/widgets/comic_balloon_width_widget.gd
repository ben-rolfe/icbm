class_name ComicBalloonWidthWidget
extends ComicWidthWidget

#func dragged(global_position:Vector2):
##	serves.width = Comic.book.snap(abs(global_position.x - serves.center_point.x) * 2)
	#serves.width = Comic.book.snap(abs(global_position.x - serves.center_point.x) * 2)
	##serves.width = Comic.book.snap(abs(global_position.x - serves.center_point.x)) * (2 if is_equal_approx(serves.anchor_to.x, 0.5) else 1)
	#serves.rebuild(true)
	#Comic.book.page.redraw()

func add_menu_items(menu:PopupMenu):	
	super(menu)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Clear Fixed Width", ComicEditor.MenuCommand.DELETE)

