class_name ComicLine
extends Control

var data:Dictionary

# ------------------------------------------------------------------------------

var edge_color:Color:
	get:
		return data.get("edge_color", Comic.theme.get_color("edge_color", "Frame"))
	set(value):
		data.edge_color = value

var edge_width:int:
	get:
		return data.get("edge_width", Comic.theme.get_constant("edge_width", "Frame"))
	set(value):
		data.edge_width = value

var fill_color:Color:
	get:
		return data.get("fill_color", Comic.theme.get_color("fill_color", "Frame"))
	set(value):
		data.fill_color = value

var fill_width:int:
	get:
		return data.get("fill_width", Comic.theme.get_constant("fill_width", "Frame"))
	set(value):
		data.fill_width = value

var layer:int:
	get:
		return data.get("layer", Comic.theme.get_constant("layer", "Frame"))
	set(value):
		data.layer = value

var oid:int:
	get:
		return data.oid

# ------------------------------------------------------------------------------

func _init(data:Dictionary, page:ComicPage):
	self.data = data
	if not data.has("otype"):
		data.otype = "balloon"
	if not data.has("oid"):
		data.oid = page.make_oid()
	page.os[oid] = self

	name = str("Line (", oid, ")")

func draw_edge(layer:ComicLayer):
	if data.points.size() > 1:
		layer.draw_polyline(data.points, edge_color, fill_width + 2 * edge_width, true)

func draw_fill(layer:ComicLayer):
	if data.points.size() > 1:
		layer.draw_polyline(data.points, fill_color, fill_width, true)
