class_name ComicLine
extends Control

var _data:Dictionary
var _default_data:Dictionary

# ------------------------------------------------------------------------------

var edge_color:Color:
	get:
		return _data_get("edge_color")
	set(value):
		_data_set("edge_color", value)

var edge_width:int:
	get:
		return _data_get("edge_width")
	set(value):
		_data_set("edge_width", value)

var fill_color:Color:
	get:
		return _data_get("fill_color")
	set(value):
		_data_set("fill_color", value)

var fill_width:int:
	get:
		return _data_get("fill_width")
	set(value):
		_data_set("fill_width", value)

var fragment:String:
	get:
		return _data_get("fragment")
	set(value):
		_data_set("fragment", value)

var layer:int:
	get:
		return _data_get("layer")
	set(value):
		_data_set("layer", value)

var oid:int:
	get:
		return _data.oid
	set(value):
		_data.oid = value

var presets:Array:
	get:
		if not _data.has("presets"):
			_data.presets = []
		return _data.presets
	set(value):
		_data.presets = value

# ------------------------------------------------------------------------------

func _init(data:Dictionary, page:ComicPage):
	_data = data
	_default_data = Comic.get_preset_data("line", presets)
	if not _data.has("otype"):
		_data.otype = "line"
	if not _data.has("oid"):
		_data.oid = page.make_oid()
	page.os[oid] = self

	name = str("Line (", oid, ")")

func apply_data():
	_default_data = Comic.get_preset_data("line", presets)

func draw_edge(draw_layer:ComicLayer):
	if _data.points.size() > 1:
		draw_layer.draw_polyline(_data.points, edge_color, fill_width + 2 * edge_width, true)

func draw_fill(draw_layer:ComicLayer):
	if _data.points.size() > 1:
		draw_layer.draw_polyline(_data.points, fill_color, fill_width, true)

# ------------------------------------------------------------------------------

func _data_get(key:Variant):
	return _data.get(key, _default_data[key])

func _data_set(key:Variant, value:Variant):
	if value == _default_data[key]:
		_data.erase(key)
	else:
		_data[key] = value
