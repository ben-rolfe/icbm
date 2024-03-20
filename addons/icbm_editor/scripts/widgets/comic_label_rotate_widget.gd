class_name ComicLabelRotateWidget
extends ComicWidget

const HANDLE_LENGTH:float = 100

func _init(serves:ComicEditorLabel):
	action = Action.TURN
	color = Color.WHITE
	super(serves)

func reposition():
	# For non-left alignment, we make sure that the rotation handle doesn't interfere with the curve handles by setting it to at least the beginning of the label.
	match serves.align:
		HORIZONTAL_ALIGNMENT_LEFT:
			anchor = serves.anchor - serves.get_transform().x * HANDLE_LENGTH
		HORIZONTAL_ALIGNMENT_CENTER:
			anchor = serves.anchor - serves.get_transform().x * max(HANDLE_LENGTH, serves.width * 0.5)
		HORIZONTAL_ALIGNMENT_RIGHT:
			anchor = serves.anchor - serves.get_transform().x * max(HANDLE_LENGTH, serves.width)

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(serves)])
	super(at_position)

func dragged(global_position:Vector2):
	serves.r = (serves.anchor - global_position).angle()
	serves.rebuild(false)

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "undo.svg")), "Reset", ComicEditor.MenuCommand.DEFAULT)
	if serves.r == 0:
		menu.set_item_disabled(-1, true)

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DEFAULT:
			Comic.book.add_undo_step([ComicReversionData.new(serves)])
			serves.r = 0
			serves.rebuild(false)

func draw_connector(layer):
	layer.draw_line(anchor, get_adjusted_anchor(), HALO_COLOR, THIN + HALO_THICKNESS)
	layer.draw_line(anchor, get_adjusted_anchor(), color, THIN)

func get_adjusted_anchor():
	match serves.align:
		HORIZONTAL_ALIGNMENT_LEFT:
			return serves.anchor
		HORIZONTAL_ALIGNMENT_CENTER:
			return serves.anchor - serves.get_transform().x * (serves.width * 0.5)
		HORIZONTAL_ALIGNMENT_RIGHT:
			return serves.anchor - serves.get_transform().x * serves.width
