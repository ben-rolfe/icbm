class_name ComicLayer
extends Control

var depth:int

func _init(_depth:int):
	depth = _depth
	name = str("Layer ", depth)

func _draw():
	# First we draw all the edges
	for child in get_children():
		if child.is_visible() and child.has_method("draw_edge"):
			child.draw_edge(self)

	# Then we draw all the fills
	for child in get_children():
		if child.is_visible() and child.has_method("draw_fill"):
			child.draw_fill(self)

	# And finally anything that goes on top of the fills.
	for child in get_children():
		if child.is_visible() and child.has_method("draw_over"):
			child.draw_over(self)
