class_name ComicKaboomWaveHeightWidget
extends ComicWidget

var kaboom:ComicEditorKaboom
var property_name = "wave_height"

func _init(serves:ComicEditorKaboom):
	super(serves)
	action = Action.SLIDE_V
	color = Color.ORANGE
	kaboom = serves

func reposition():
	anchor = get_adjusted_anchor() - kaboom.get_transform().y * kaboom[property_name] * kaboom.width

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(kaboom)])
	super(at_position)

func dragged(global_position:Vector2):
	var t:Transform2D = serves.get_transform()
	var p:Vector2 = Geometry2D.get_closest_point_to_segment_uncapped(global_position, t.origin, t.origin + t.y) - t.origin
	if sign(p.x) == sign(t.y.x) and sign(p.y) == sign(t.y.y):
		set_by_distance(-p.length())
	else:
		set_by_distance(p.length())
	
	kaboom.rebuild(false)
	
func set_by_distance(distance:float):
	kaboom[property_name] = distance / kaboom.width

func add_menu_items(menu:PopupMenu):
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "undo.svg")), "Reset", ComicEditor.MenuCommand.DEFAULT)
	menu.add_icon_item(load(str(ComicEditor.DIR_ICONS, "checked" if kaboom.rotate_chars else "unchecked", ".svg")), "Rotate Characters with Curve", ComicEditor.MenuCommand.TOGGLE)

func menu_command_pressed(id:int):
	match id:
		ComicEditor.MenuCommand.DEFAULT:
			Comic.book.add_undo_step([ComicReversionData.new(kaboom)])
			kaboom.clear_data(property_name)
			kaboom.rebuild(false)
		ComicEditor.MenuCommand.TOGGLE:
			Comic.book.add_undo_step([ComicReversionData.new(kaboom)])
			kaboom.rotate_chars = not kaboom.rotate_chars
			kaboom.rebuild(false)

func get_adjusted_anchor():
	match kaboom.align:
		HORIZONTAL_ALIGNMENT_LEFT:
			return serves.anchor + serves.get_transform().x * serves.width * serves.wave_period * 0.25
		HORIZONTAL_ALIGNMENT_CENTER:
			return serves.anchor + serves.get_transform().x * serves.width * (serves.wave_period * 0.25 - 0.5)
		HORIZONTAL_ALIGNMENT_RIGHT:
			return serves.anchor + serves.get_transform().x * serves.width * (serves.wave_period * 0.25 - 1)

func draw_connector(layer):
	#TODO: Draw a sin wave from the wave period widget through this point instead.
	if serves is ComicKaboom:
		# Draw the connector to the left side of the kaboom, not its anchor.
		var target_point:Vector2 = serves.anchor
		match serves.align:
			HORIZONTAL_ALIGNMENT_CENTER:
				target_point = serves.anchor - serves.get_transform().x * (serves.width * 0.5)
			HORIZONTAL_ALIGNMENT_RIGHT:
				target_point =  serves.anchor - serves.get_transform().x * serves.width
		layer.draw_line(anchor, target_point, HALO_COLOR, THIN + HALO_THICKNESS)
		layer.draw_line(anchor, target_point, color, THIN)
	else:
		# Draw the connector to the left anchor of the served widget 
		super(layer)

