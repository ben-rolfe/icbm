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

var _data:Dictionary
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
		return _data.oid
	set(value):
		_data.oid = value

var order:int:
	get:
		return _data.get("order", 0)
	set(value):
		_data.order = value

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
			
#-------------------------------------------------------------------------------

func _init(data:Dictionary, page:ComicPage):
	super()
	_data = data
	_default_data = Comic.get_preset_data("button", presets)
	if not _data.has("otype"):
		_data.otype = "button"
	if not _data.has("oid"):
		oid = page.make_oid()
	page.os[oid] = self

	# Each button has its own stylebox
	style_box = theme.get_stylebox("normal", "ComicTextBlock").duplicate()
	add_theme_stylebox_override("normal", style_box)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	bbcode_enabled = true
	fit_content = true

	if not self is ComicEditorButton:
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

	# Buttons are in their own object so, unlike for elements in the page, there's no reason not to immediately apply the data.
	apply_data()



func apply_data():
	_default_data = Comic.get_preset_data("button", presets)
	text = str("[center]", Comic.parse_rich_text_string(content), "[/center]")
	set_theme_override()

	if shown:
		show()
	else:
		hide()

func _gui_input(event):
	if enabled and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and hovered:
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
		style_box.border_color = fill_color_disabled
	else:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if hovered:
			add_theme_color_override("default_color", font_color_hovered)
			style_box.bg_color = fill_color_hovered
			style_box.border_color = fill_color_hovered
		else:
			add_theme_color_override("default_color", font_color)
			style_box.bg_color = fill_color
			style_box.border_color = fill_color

# ------------------------------------------------------------------------------

func _data_get(key:Variant):
	return _data.get(key, _default_data[key])

func _data_set(key:Variant, value:Variant):
	if value == _default_data[key]:
		_data.erase(key)
	else:
		_data[key] = value
