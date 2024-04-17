class_name ComicKaboomWaveHeightWidget
extends ComicWidget

const DISTANCE_MULTIPLIER:float = 0.006

var label:ComicEditorKaboom
var property_name = "wave_height"

func _init(serves:ComicEditorKaboom):
	super(serves)
	action = Action.SLIDE_V
	color = Color.ORANGE
	label = serves

func reposition():
	# Note that this 0.5, and the *2 in the dragged method, are arbitrary.
	anchor = get_adjusted_anchor() - serves.get_transform().y * label[property_name] * label.font_size / DISTANCE_MULTIPLIER

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(label)])
	super(at_position)

func dragged(global_position:Vector2):
	var t:Transform2D = serves.get_transform()
	var p:Vector2 = Geometry2D.get_closest_point_to_segment_uncapped(global_position, t.origin, t.origin + t.y) - t.origin
	if sign(p.x) == sign(t.y.x) and sign(p.y) == sign(t.y.y):
		set_by_distance(-p.length())
	else:
		set_by_distance(p.length())
	
#	set_by_distance(t.origin.distance_to(Geometry2D.get_closest_point_to_segment_uncapped(global_position, t.origin, t.origin - t.y)))
	label.rebuild(false)
	
func set_by_distance(distance:float):
	label[property_name] = distance / label.font_size * DISTANCE_MULTIPLIER

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "undo.svg")), "Reset", ComicEditor.MenuCommand.DEFAULT)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "checked" if label.rotate_chars else "unchecked", ".svg")), "Rotate Characters with Curve", ComicEditor.MenuCommand.TOGGLE)

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DEFAULT:
			Comic.book.add_undo_step([ComicReversionData.new(label)])
			label[property_name] = label.default_data[property_name]
			label.rebuild(false)
		ComicEditor.MenuCommand.TOGGLE:
			Comic.book.add_undo_step([ComicReversionData.new(label)])
			label.rotate_chars = not label.rotate_chars
			label.rebuild(false)

func get_adjusted_anchor():
	match label.align:
		HORIZONTAL_ALIGNMENT_LEFT:
			return serves.anchor + serves.get_transform().x * serves.width * serves.wave_period * 0.25
		HORIZONTAL_ALIGNMENT_CENTER:
			return serves.anchor + serves.get_transform().x * serves.width * (serves.wave_period * 0.25 - 0.5)
		HORIZONTAL_ALIGNMENT_RIGHT:
			return serves.anchor + serves.get_transform().x * serves.width * (serves.wave_period * 0.25 - 1)
	
