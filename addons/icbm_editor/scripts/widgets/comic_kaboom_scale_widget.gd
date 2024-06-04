class_name ComicKaboomScaleWidget
extends ComicWidget

const DISTANCE_MULTIPLIER:float = 0.032

var property_name = "font_size"
var kaboom:ComicKaboom

func _init(serves:ComicEditorKaboom):
	kaboom = serves
	action = Action.SLIDE_V
	color = Color.GREEN
	super(serves)

func reposition():
	anchor = get_adjusted_anchor() - kaboom.get_transform().y * (kaboom[property_name] / DISTANCE_MULTIPLIER)

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(kaboom)])
	super(at_position)

func dragged(global_position:Vector2):
	set_by_distance(get_adjusted_anchor().distance_to(Geometry2D.get_closest_point_to_segment_uncapped(global_position, get_adjusted_anchor(), anchor)))
	kaboom.rebuild(false)
	
func set_by_distance(distance:float):
	kaboom[property_name] = max(8, distance) * DISTANCE_MULTIPLIER

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "undo.svg")), "Reset", ComicEditor.MenuCommand.DEFAULT)
	if kaboom.is_default(property_name):
		menu.set_item_disabled(-1, true)

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DEFAULT:
			Comic.book.add_undo_step([ComicReversionData.new(kaboom)])
			kaboom.clear_data(property_name)
			kaboom.rebuild(false)

func get_adjusted_anchor():
	match kaboom.align:
		HORIZONTAL_ALIGNMENT_LEFT:
			return kaboom.anchor
		HORIZONTAL_ALIGNMENT_CENTER:
			return kaboom.anchor - kaboom.get_transform().x * (kaboom.width * 0.5)
		HORIZONTAL_ALIGNMENT_RIGHT:
			return kaboom.anchor - kaboom.get_transform().x * kaboom.width

func draw_connector(layer):
	# Don't draw the connector for the scale widget, but do draw it for its children
	if not serves is ComicKaboom:
		super(layer)
