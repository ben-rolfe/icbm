class_name ComicButton
extends ComicTextBlock

enum Action {
	DO_NOTHING,
	NEXT,
	PREVIOUS,
	GO,
	BACK,
	VISIT,
	RETURN,
	PARSE_COMMANDS,
}

var click_lines:Array[String] = []
var key_string:String

var data:Dictionary
var _default_data:Dictionary

var style_box:StyleBoxFlat

#-------------------------------------------------------------------------------

var action:Action:
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

var content:String:
	get:
		return _data_get("content")
	set(value):
		_data_set("content", value)

var enabled:bool = true:
	set(value):
		enabled = value
		set_theme_override()

var fill_color:Color:
	get:
		return _data_get("fill_color")
	set(value):
		_data_set("fill_color", value)

var fill_color_disabled:Color:
	get:
		return _data_get("fill_color_disabled")
	set(value):
		_data_set("fill_color_disabled", value)

var fill_color_hovered:Color:
	get:
		return _data_get("fill_color_hovered")
	set(value):
		_data_set("fill_color_hovered", value)

var font_color:Color:
	get:
		return _data_get("font_color")
	set(value):
		_data_set("font_color", value)

var font_color_disabled:Color:
	get:
		return _data_get("font_color_disabled")
	set(value):
		_data_set("font_color_disabled", value)

var font_color_hovered:Color:
	get:
		return _data_get("font_color_hovered")
	set(value):
		_data_set("font_color_hovered", value)

var fragment:String:
	get:
		return _data_get("fragment")
	set(value):
		_data_set("fragment", value)

var hovered: bool = false:
	set(value):
		hovered = value
		set_theme_override()

var oid:int:
	get:
		return data.oid
	set(value):
		data.oid = value

var presets:Array:
	get:
		if not data.has("presets"):
			data.presets = []
		return data.presets
	set(value):
		data.presets = value

#-------------------------------------------------------------------------------

func _init(_data:Dictionary, page:ComicPage):
	super()
	data = _data
	_default_data = Comic.get_preset_data("button", presets)
	if not data.has("otype"):
		data.otype = "button"
	if not data.has("oid"):
		oid = page.make_oid()
	page.os[oid] = self

	# Each button has its own stylebox
	style_box = theme.get_stylebox("normal", "ComicTextBlock").duplicate()
	add_theme_stylebox_override("normal", style_box)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	bbcode_enabled = true
	fit_content = true
	# Buttons are in their own object so, unlike for elements in the page, there's no reason not to immediately apply the data.
	apply_data()

func apply_data():
	_default_data = Comic.get_preset_data("button", presets)
	text = str("[center]", content, "[/center]")
	set_theme_override()

func _gui_input(event):
	if enabled and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and get_global_rect().has_point(event.global_position):
			activate()

func _input(event):
	if enabled and event is InputEventKey:
		# We check the last character of the keycode text, to catch both "3" and "Kp 3"
		if event.pressed and event.as_text_keycode()[-1] == key_string:
			activate()

func _on_mouse_entered():
	hovered = true

func _on_mouse_exited():
	hovered = false

func activate():
	match action:
		Action.GO:
			Comic.book.page_go(action_bookmark)
		Action.BACK:
			Comic.book.page_back()
		Action.NEXT:
			Comic.book.page_next()
		Action.PREVIOUS:
			Comic.book.page_previous()
		Action.VISIT:
			Comic.book.page_visit(action_bookmark)
		Action.RETURN:
			Comic.book.page_return()
		Action.PARSE_COMMANDS:
			Comic.parse_hidden_string(action_commands)

func set_theme_override():
	if !enabled:
		mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		add_theme_color_override("default_color", font_color_disabled)
		style_box.bg_color = fill_color_disabled
	else:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if hovered:
			add_theme_color_override("default_color", font_color_hovered)
			style_box.bg_color = fill_color_hovered
		else:
			add_theme_color_override("default_color", font_color)
			style_box.bg_color = fill_color

# ------------------------------------------------------------------------------

func _data_get(key:Variant):
	return data.get(key, _default_data[key])

func _data_set(key:Variant, value:Variant):
	if value == _default_data[key]:
		data.erase(key)
	else:
		data[key] = value
