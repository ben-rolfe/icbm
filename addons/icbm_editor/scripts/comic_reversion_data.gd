class_name ComicReversionData
extends ComicReversion

var data

func _init(o:Object, focus_after:bool = true):
	super()
	self.o = o
	data = o._data.duplicate(true)
	self.focus_after = focus_after

func apply() -> ComicReversionData:
	var r = ComicReversionData.new(o, focus_after)
	o._data = data.duplicate(true)
	if o.has_method("after_reversion"):
		o.after_reversion()
	super()
	return r
