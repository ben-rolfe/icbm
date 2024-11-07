class_name ComicHotspot
extends Area2D

var _data:Dictionary
var _default_data:Dictionary
var polygon:CollisionPolygon2D

# ------------------------------------------------------------------------------

var action:ComicButton.Action:
	get:
		return _data_get("action")
	set(value):
		_data_set("action", value)

var action_bookmark:String:
	get:
		return _data_get("action_bookmark")
	set(value):
		_data_set("action_bookmark", value)

var action_commands:String:
	get:
		return _data_get("action_commands")
	set(value):
		_data_set("action_commands", value)
		
var anchor:Vector2:
	get:
		return _data_get("anchor")
	set(value):
		_data_set("anchor", value)

var appear:int:
	get:
		return _data_get("appear")
	set(value):
		_data_set("appear", value)

var appear_type:int:
	get:
		return _data_get("appear_type")
	set(value):
		_data_set("appear_type", value)
		
var disappear:int:
	get:
		return _data_get("disappear")
	set(value):
		_data_set("disappear", value)

var disappear_type:int:
	get:
		return _data_get("disappear_type")
	set(value):
		_data_set("disappear_type", value)
			
var change_cursor:bool:
	get:
		return _data_get("change_cursor")
	set(value):
		_data_set("change_cursor", value)

var fragment:String:
	get:
		return _data_get("fragment")
	set(value):
		_data_set("fragment", value)

var oid:int:
	get:
		return _data.oid
	set(value):
		_data.oid = value

var points:Array:
	get:
		return _data_get("points")
	set(value):
		_data_set("points", value)

var presets:Array:
	get:
		if not _data.has("presets"):
			_data.presets = []
		return _data.presets
	set(value):
		_data.presets = value

var shown:bool:
	get:
		return _data_get("shown")
	set(value):
		_data_set("shown", value)
		if not Comic.book is ComicEditor:
			if value:
				show()
			else:
				hide()

# ------------------------------------------------------------------------------

func _init(data:Dictionary, page:ComicPage):
	_data = data
	_default_data = Comic.get_preset_data("hotspot", presets)
	if not _data.has("otype"):
		_data.otype = "hotspot"
	if not _data.has("oid"):
		oid = page.make_oid()
	if not _data.has("points"):
		points = [Vector2(0,0), Vector2(288,0), Vector2(288,96), Vector2(0,96)]

	page.os[oid] = self
	name = str("Hotspot (", oid, ")")
	polygon = CollisionPolygon2D.new()
	add_child(polygon)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if not self is ComicEditorHotspot:
		if appear_type == 1: # Milliseconds delay
			Comic.book.timers.push_back({
				"t": appear / 1000.0,
				"s": str("[store oid=", oid, " var=shown]true[/store]")
			})
		elif appear_type == 2: # Clicks delay
			Comic.book.click_counters.push_back({
				"clicks": appear,
				"s": str("[store oid=", oid, " var=shown]true[/store]")
			})

		if disappear_type == 1: # Milliseconds delay
			Comic.book.timers.push_back({
				"t": disappear / 1000.0,
				"s": str("[store oid=", oid, " var=shown]false[/store]")
			})
		elif disappear_type == 2: # Clicks delay
			Comic.book.click_counters.push_back({
				"clicks": disappear,
				"s": str("[store oid=", oid, " var=shown]false[/store]")
			})

func apply_data():
	# First, we recreate the _default_data dictionary, because it is affected by selected presets, which may have changed
	_default_data = Comic.get_preset_data("hotspot", presets)
	position = anchor
	polygon.polygon = points

	if shown:
		show()
	else:
		hide()

func rebuild(_rebuild_sub_objects:bool = false):
	apply_data()

func _on_mouse_entered():
	Comic.book.page.enter_hotspot(self)

func _on_mouse_exited():
	Comic.book.page.exit_hotspot(self)
	
func activate():
	match action:
		ComicButton.Action.GO:
			Comic.book.page_go(action_bookmark)
		ComicButton.Action.BACK:
			Comic.book.page_back()
		ComicButton.Action.NEXT:
			Comic.book.page_next()
		ComicButton.Action.PREVIOUS:
			Comic.book.page_previous()
		ComicButton.Action.VISIT:
			Comic.book.page_visit(action_bookmark)
		ComicButton.Action.RETURN:
			Comic.book.page_return()
		ComicButton.Action.PARSE_COMMANDS:
			Comic.parse_hidden_string(action_commands)

# ------------------------------------------------------------------------------

func is_default(key:Variant) -> bool:
	return _data_get(key) == _default_data[key]

func clear_data(key:Variant):
	_data.erase(key)

func _data_get(key:Variant) -> Variant:
	return _data.get(key, _default_data[key])

func _data_set(key:Variant, value:Variant):
	if value == _default_data[key]:
		_data.erase(key)
	else:
		_data[key] = value
