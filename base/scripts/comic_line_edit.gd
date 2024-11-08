class_name ComicLineEdit
extends LineEdit

var _data:Dictionary
var _default_data:Dictionary

var style_box:StyleBoxFlat

#-------------------------------------------------------------------------------

var align:int:
	get:
		return _data_get("align")
	set(value):
		_data_set("align", value)

var anchor:Vector2:
	get:
		return _data_get("anchor")
	set(value):
		_data_set("anchor", value)

var anchor_to:Vector2:
	get:
		return _data_get("anchor_to")
	set(value):
		_data_set("anchor_to", value)

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

var default_text:String:
	get:
		return _data_get("default_text")
	set(value):
		_data_set("default_text", value)
		
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
			
var edge_color:Color:
	get:
		return _data_get("edge_color")
	set(value):
		_data_set("edge_color", value)

var edge_color_disabled:Color:
	get:
		return _data_get("edge_color_disabled")
	set(value):
		_data_set("edge_color_disabled", value)

var edge_width:int:
	get:
		return _data_get("edge_width")
	set(value):
		_data_set("edge_width", value)

var enabled:bool = true:
	set(value):
		enabled = value
		set_theme_override()

var enabled_test:String:
	get:
		return _data_get("enabled_test")
	set(value):
		_data_set("enabled_test", value)

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

var placeholder_color:Color:
	get:
		return _data_get("placeholder_color")
	set(value):
		_data_set("placeholder_color", value)

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
		if not self is ComicEditorLineEdit:
			if value:
				show()
			else:
				hide()

var var_name:String:
	get:
		return _data_get("var_name")
	set(value):
		_data_set("var_name", value)

var width:float:
	get:
		return _data_get("width")
	set(value):
		_data_set("width", value)

#-------------------------------------------------------------------------------

func _init(data:Dictionary, page:ComicPage):
	theme = preload("res://theme/default.tres")
	_data = data
	_default_data = Comic.get_preset_data("line_edit", presets)
	if not _data.has("otype"):
		_data.otype = "line_edit"
	if not _data.has("oid"):
		oid = page.make_oid()
	page.os[oid] = self

	# Each line_edit has its own stylebox
	style_box = theme.get_stylebox("normal", "LineEdit").duplicate()
	add_theme_stylebox_override("normal", style_box)
	add_theme_stylebox_override("read_only", style_box)
	
	if not _data.has("anchor"):
		_data.anchor = Vector2.ZERO
	context_menu_enabled = false
	text_changed.connect(_on_text_changed)
	#caret_changed.connect(_on_changed)
	#focus_entered.connect(_on_entered)
	#focus_exited.connect(_on_changed)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if self is ComicEditorLineEdit:
		# Note that we do this in either case, we just to stuff both before and after in the other case.
		apply_data()
	else:
		# If the var is not already set, then set it to the default
		if not Comic.vars.has(var_name):
			Comic.set_var(var_name, default_text)

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
		apply_data()
		# We only do this once, on load, because we wouldn't want to clear a default of "Ben" in the middle of the user writing "Benjamin"
		if text == default_text:
			text = ""

func apply_data():
	_default_data = Comic.get_preset_data("line_edit", presets)
	var pre_text:String
	var post_text:String

	alignment = align

	text = Comic.parse_rich_text_string(Comic.get_var(var_name, default_text))
	placeholder_text = default_text
	position = anchor
	size = Vector2(width, 0)
	enabled = self is ComicEditorLineEdit or Comic.parse_bool_string(Comic.execute_embedded_code(enabled_test))

	set_theme_override()
	if shown:
		show()
	else:
		hide()

func _on_text_changed(s:String):
	Comic.set_var(var_name, s)

func _on_mouse_entered():
	hovered = true

func _on_mouse_exited():
	hovered = false
	
func set_theme_override():
	add_theme_color_override("font_placeholder_color", placeholder_color)
	style_box.set_border_width_all(edge_width)
	if self is ComicEditorLineEdit or enabled:
		mouse_default_cursor_shape = Control.CURSOR_IBEAM
		add_theme_color_override("font_color", font_color)
		add_theme_color_override("caret_color", font_color)
		add_theme_color_override("font_uneditable_color", font_color)
		style_box.bg_color = fill_color
		style_box.border_color = edge_color
		# Although uneditable in the editor, the line_edit must be enabled to catch clicks, so its text is selectable, which we don't really want, so we hide it.
		if self is ComicEditorLineEdit:
			add_theme_color_override("selection_color", Color.TRANSPARENT)
			add_theme_color_override("font_selected_color", font_color)
	else:
		mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		add_theme_color_override("font_color", font_color_disabled)
		add_theme_color_override("caret_color", font_color_disabled)
		add_theme_color_override("font_uneditable_color", font_color_disabled)
		style_box.bg_color = fill_color_disabled
		style_box.border_color = edge_color_disabled

# ------------------------------------------------------------------------------

func _data_get(key:Variant):
	return _data.get(key, _default_data[key])

func _data_set(key:Variant, value:Variant):
	if value == _default_data[key]:
		_data.erase(key)
	else:
		_data[key] = value
