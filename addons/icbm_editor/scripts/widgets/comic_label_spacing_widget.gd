class_name ComicLabelSpacingWidget
extends ComicWidget

func _init(serves:ComicEditorLabel):
	action = Action.SLIDE_H
	color = Color.CYAN
	super(serves)

func reposition():
	if serves.align == HORIZONTAL_ALIGNMENT_RIGHT:
		anchor = get_adjusted_anchor() - serves.get_transform().x * serves.width + serves.get_transform().y * serves.font_size * 0.5
	else:
		anchor = get_adjusted_anchor() + serves.get_transform().x * serves.width + serves.get_transform().y * serves.font_size * 0.5
	#match serves.align:
		#HORIZONTAL_ALIGNMENT_LEFT:
			#anchor = get_adjusted_anchor() + serves.get_transform().x * serves.width + serves.get_transform().y * serves.font_size * 0.5
		#HORIZONTAL_ALIGNMENT_CENTER:
			#anchor = get_adjusted_anchor() - serves.get_transform().x * serves.width + serves.get_transform().y * serves.font_size * 0.5
		#HORIZONTAL_ALIGNMENT_RIGHT:
			#anchor = get_adjusted_anchor() + serves.get_transform().x * serves.width / 2 + serves.get_transform().y * serves.font_size * 0.5
	
func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(serves)])
	super(at_position)

func dragged(global_position:Vector2):
	var d = get_adjusted_anchor().distance_to(Geometry2D.get_closest_point_to_segment_uncapped(global_position, get_adjusted_anchor(), anchor))
	d /= get_adjusted_anchor().distance_to(anchor)
	serves.spacing = max(0.01, serves.spacing * d)
	serves.rebuild(false)

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "undo.svg")), "Reset", ComicEditor.MenuCommand.DEFAULT)
	if serves.spacing == 1:
		menu.set_item_disabled(-1, true)

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DEFAULT:
			Comic.book.add_undo_step([ComicReversionData.new(serves)])
			serves.spacing = 1
			serves.rebuild(false)

func draw_connector(layer):
	pass
	#var to_point:Vector2
	#match serves.align:
		#HORIZONTAL_ALIGNMENT_LEFT:
			#to_point = serves.anchor + serves.get_transform().x * serves.width
		#HORIZONTAL_ALIGNMENT_CENTER:
			#anchor = serves.anchor + serves.get_transform().x * serves.width * 0.5
		#HORIZONTAL_ALIGNMENT_RIGHT:
			#anchor = serves.anchor
	#layer.draw_line(anchor, to_point, HALO_COLOR, THIN + HALO_THICKNESS)
	#layer.draw_line(anchor, to_point, color, THIN)

func get_adjusted_anchor():
	match serves.align:
		HORIZONTAL_ALIGNMENT_LEFT:
			return serves.anchor
		HORIZONTAL_ALIGNMENT_CENTER:
			return serves.anchor - serves.get_transform().x * (serves.width * 0.5)
		HORIZONTAL_ALIGNMENT_RIGHT:
			return serves.anchor

