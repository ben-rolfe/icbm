class_name ComicTailStartWidget
extends ComicWidget

var v_id:String = "v_start"
var p_id:String = "p_start"
var has_custom_vector:bool:
	get:
		return serves.data.has(v_id)
	set(value):
		if value != has_custom_vector:
			if value:
				serves.data[v_id] = serves[v_id]
			else:
				serves.data.erase(v_id)
			serves.balloon.rebuild(true)
			serves.balloon.rebuild_widgets()

var custom_vector:Vector2:
	get:
		return serves.data[v_id]
	set(value):
		serves.data[v_id] = value
		serves.balloon.rebuild_tail(serves.oid)
		Comic.book.page.redraw()


func _init(serves:ComicTail):
	action = ComicWidget.Action.MOVE
	super(serves)
	color = Color.PURPLE
	name = "Tail Start"

func reposition():
	anchor = serves[p_id]

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(serves.balloon)])
	super(at_position)

func dragged(global_position:Vector2):
	serves.data.start_placement_angle = (global_position - serves.balloon.center_point).angle()
	serves.balloon.rebuild_tail(serves.oid)
	Comic.book.page.redraw()

func add_menu_items(menu:PopupMenu):
	# Style and Tip Submenu
	var menu_style:PopupMenu = PopupMenu.new()
	menu.add_child(menu_style)
	menu_style.index_pressed.connect(menu_style_index_pressed)
	menu_style.name = "style"
	for key in Comic.tail_styles:
		menu_style.add_icon_item(Comic.tail_styles[key].editor_icon, Comic.tail_styles[key].editor_name)
		if key == serves.style.id:
			menu_style.set_item_disabled(-1, true)
	if serves.style.supports_tips:
		menu_style.add_separator("Tip")
		for key in Comic.tail_tips:
			menu_style.add_icon_item(Comic.tail_tips[key].editor_icon, Comic.tail_tips[key].editor_name)
			if key == serves.tip.id:
				menu_style.set_item_disabled(-1, true)

	# Main Tail Widget
	menu.add_submenu_item("Tail Style", "style")
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, str("dice_", randi_range(1, 6), ".svg"))), "Rerandomize Tail", ComicEditor.MenuCommand.RANDOMIZE)
	if not serves.style.is_randomized and not serves.tip.is_randomized:
		menu.set_item_disabled(-1, true)
	menu.add_separator()
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "handle.svg")), "Remove Handle" if has_custom_vector else "Add Handle", ComicEditor.MenuCommand.TOGGLE)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "delete.svg")), "Remove Tail", ComicEditor.MenuCommand.DELETE)

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DELETE:
			Comic.book.add_undo_step([ComicReversionData.new(serves.balloon)])
			serves.balloon.delete_tail(serves.oid)
			Comic.book.page.redraw(true)
			Comic.book.page.rebuild_widgets()
		ComicEditor.MenuCommand.RANDOMIZE:
			Comic.book.add_undo_step([ComicReversionData.new(serves.balloon)])
			serves.data.seed = randi()
			serves.balloon.rebuild_tail(serves.oid)
			Comic.book.page.redraw()
		ComicEditor.MenuCommand.TOGGLE:
			Comic.book.add_undo_step([ComicReversionData.new(serves.balloon)])
			has_custom_vector = not has_custom_vector

func menu_style_index_pressed(index:int):
	Comic.book.add_undo_step([ComicReversionData.new(serves.balloon)])
	if index > Comic.tail_styles.size():
		index -= Comic.tail_styles.size() + 1 # +1 because the divider counts as an indexed item.
		serves.data.tip = Comic.tail_tips.keys()[index]
	else:
		serves.data.style = Comic.tail_styles.keys()[index]
	serves.balloon.rebuild_tails()
	Comic.book.page.redraw(true)
