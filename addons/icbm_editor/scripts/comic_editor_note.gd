class_name ComicEditorNote
extends CodeEdit
#NOTE: Unlike most editor controls, this doesn't extend a viewer control, because notes don't appear in the viewer.

var data:Dictionary
var default_data:Dictionary

#-------------------------------------------------------------------------------

var anchor:Vector2:
	get:
		return _data_get("anchor")
	set(value):
		_data_set("anchor", value)

var layer:int:
	get:
		return _data_get("layer")
	set(value):
		_data_set("layer", value)

var oid:int:
	get:
		return data.oid
	set(value):
		data.oid = value

var h:float:
	get:
		return _data_get("h")
	set(value):
		_data_set("h", value)

var w:float:
	get:
		return _data_get("w")
	set(value):
		_data_set("w", value)

#-------------------------------------------------------------------------------

func _init(data:Dictionary, page:ComicPage):
	theme = Comic.theme
	self.data = data
	default_data = _get_default_data()
	if not data.has("oid"):
		data.oid = Comic.book.page.make_oid()
	page.os[oid] = self
	if not data.has("anchor"):
		data.anchor = Vector2.ZERO

func _data_get(key:Variant):
	return data.get(key, default_data[key])

func _data_set(key:Variant, value:Variant):
	if value == default_data[key]:
		data.erase(key)
	else:
		data[key] = value

func apply_data():
	position = anchor
	size = Vector2(w, h)

func rebuild(_rebuild_subobjects:bool = false):
	apply_data()
	Comic.book.page.redraw()

static func _get_default_data() -> Dictionary:
	return {
		"anchor": Vector2.ZERO,
		"h": 300,
		"layer": 0,
		"text": "",
		"w": 300,
	}
