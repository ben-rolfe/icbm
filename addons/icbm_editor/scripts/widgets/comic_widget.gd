class_name ComicWidget
extends Control

const RADIUS = 12
const THICK = 4
const THIN = 1
const HALO_COLOR = Color.BLACK
const HALO_THICKNESS = 1
const CIRCLE_POINTS = 13 # The number of points to draw a circle widget

enum Action {
	STATIC,
	MOVE,
	TURN,
	SLIDE_H,
	SLIDE_V,
}

var serves:Object
var color:Color
var action:Action = Action.MOVE

var anchor:Vector2:
	get:
		return position + pivot_offset
	set(value):
		position = value - pivot_offset

func _init(serves:Object):
	self.serves = serves
	size = Vector2.ONE * (RADIUS * 2)
	pivot_offset = Vector2.ONE * RADIUS
	mouse_filter = MOUSE_FILTER_PASS

func draw(layer:ComicWidgetLayer):
	if serves is CanvasItem:
		rotation = serves.rotation
	match action:
		Action.STATIC:
			mouse_default_cursor_shape = Control.CURSOR_HELP
			draw_shape(layer, 5, 0.125)
		Action.MOVE:
			mouse_default_cursor_shape = Control.CURSOR_MOVE
			draw_shape(layer)
		Action.TURN:
			mouse_default_cursor_shape = Control.CURSOR_DRAG
			draw_connector(layer)
			draw_shape(layer, 5)
		Action.SLIDE_H:
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
			draw_connector(layer)
			draw_shape(layer, 7)
		Action.SLIDE_V:
			mouse_default_cursor_shape = Control.CURSOR_VSIZE
			draw_connector(layer)
			draw_shape(layer, 7, 0.25)

func draw_shape(layer:ComicWidgetLayer, points = CIRCLE_POINTS, start = 0):
	layer.draw_arc(anchor, RADIUS, start * TAU + rotation, (start + 1) * TAU + rotation, points, HALO_COLOR, THICK + HALO_THICKNESS)
	layer.draw_arc(anchor, RADIUS, start * TAU + rotation, (start + 1) * TAU + rotation, points, color, THICK)

func draw_connector(layer):
	layer.draw_line(anchor, serves.anchor, HALO_COLOR, THIN + HALO_THICKNESS)
	layer.draw_line(anchor, serves.anchor, color, THIN)
	

func reposition():
	pass

func _get_drag_data(at_position:Vector2):
	Comic.book.grab(self, Vector2.ZERO)
	# We don't return anything because we don't really want to use the built-in drag-and drop (It doesn't work with Subviewports)
	#TODO: When Godot 4.4 is released, check if the subviewport issue has been fixed (it's not coming in 4.3, but has been slated for 4.4)

func dropped(global_position:Vector2):
	dragged(global_position)
	
func dragged(global_position:Vector2):
	pass

func _gui_input(event:InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			Comic.book.right_clicked(self, event)

