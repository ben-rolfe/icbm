class_name ComicKaboomScaleWidget
extends ComicWidget

const DISTANCE_MULTIPLIER:float = 2

var property_name = "font_size"
var label

func _init(serves:ComicEditorKaboom):
	label = serves
	action = Action.SLIDE_V
	color = Color.GREEN
	super(serves)

func reposition():
	# Note that this 0.5, and the *2 in the dragged method, are arbitrary.
	anchor = get_adjusted_anchor() - label.get_transform().y * (label[property_name] / DISTANCE_MULTIPLIER)

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(label)])
	super(at_position)

func dragged(global_position:Vector2):
	set_by_distance(get_adjusted_anchor().distance_to(Geometry2D.get_closest_point_to_segment_uncapped(global_position, get_adjusted_anchor(), anchor)))
	label.rebuild(false)
	
func set_by_distance(distance:float):
	label[property_name] = max(8, distance * DISTANCE_MULTIPLIER)

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "undo.svg")), "Reset", ComicEditor.MenuCommand.DEFAULT)
	if label[property_name] == label.default_data[property_name]:
		menu.set_item_disabled(-1, true)

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DEFAULT:
			Comic.book.add_undo_step([ComicReversionData.new(label)])
			label[property_name] = label.default_data[property_name]
			label.rebuild(false)

func get_adjusted_anchor():
	match label.align:
		HORIZONTAL_ALIGNMENT_LEFT:
			return label.anchor
		HORIZONTAL_ALIGNMENT_CENTER:
			return label.anchor - label.get_transform().x * (label.width * 0.5)
		HORIZONTAL_ALIGNMENT_RIGHT:
			return label.anchor - label.get_transform().x * label.width

