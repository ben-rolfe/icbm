class_name ComicChar
extends Control


var s:String
var font:Font
var outline_color:Color
var fill_color:Color
var font_size:int
var outline_thickness:int
var draw_offset:Vector2
var bounds:PackedVector2Array

func _init(_s:String, _font:Font, _font_size:int, _fill_color:Color, _outline_color:Color, _outline_thickness:int, _position:Vector2, _size:Vector2, _rotation:float):
	if _s == "": # Shouldn't happen, but just in case
		_s = " "
	s = _s.left(1)
	font = _font
	font_size = _font_size
	fill_color = _fill_color
	outline_color = _outline_color
	outline_thickness = _outline_thickness
	size = _size
	rotation = _rotation

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	draw_offset = Vector2(size.x * -0.5, size.y * 0.5 - font.get_descent(font_size) if font_size > 0 else 0.0)
	position = _position

	# Bounds will be used by parent for has_point
	bounds = [size / -2, Vector2(size.x, -size.y) / 2, size / 2, Vector2(-size.x, size.y) / 2, size / -2]
	for i in bounds.size():
		bounds[i] = bounds[i].rotated(rotation)

func _draw():
	if font_size > 0:
		draw_char_outline(font, draw_offset, s, font_size, outline_thickness, outline_color)
		draw_char(font, draw_offset, s, font_size, fill_color)




