class_name ComicReversionScribble
extends ComicReversion

var data:PackedByteArray

func _init():
	super()
	data = Scribble.scribble_rect.image.get_data()
	focus_after = false

func apply() -> ComicReversionScribble:
	var r = ComicReversionScribble.new()
	Scribble.scribble_rect.image.set_data(Scribble.scribble_rect.image.get_width(), Scribble.scribble_rect.image.get_height(), false, Scribble.scribble_rect.image.get_format(), data)
	Scribble.scribble_rect.apply_image()
	super()
	return r
