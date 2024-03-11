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

func _init(s:String, font:Font, font_size:int, fill_color:Color, outline_color:Color, outline_thickness:int, position:Vector2, size:Vector2, rotation:float):
	if s == "": # Shouldn't happen, but just in case
		s = " "
	self.s = s.left(1)
	self.font = font
	self.font_size = font_size
	self.fill_color = fill_color
	self.outline_color = outline_color
	self.outline_thickness = outline_thickness
	self.size = size
	self.rotation = rotation

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	draw_offset = Vector2(size.x * -0.5, size.y * 0.5 - font.get_descent(font_size) if font_size > 0 else 0)
	self.position = position

	# Bounds will be used by parent for has_point
	bounds = [size / -2, Vector2(size.x, -size.y) / 2, size / 2, Vector2(-size.x, size.y) / 2, size / -2]
	for i in bounds.size():
		bounds[i] = bounds[i].rotated(rotation)

func _draw():
	if font_size > 0:
		draw_char_outline(font, draw_offset, s, font_size, outline_thickness, outline_color)
		draw_char(font, draw_offset, s, font_size, fill_color)




