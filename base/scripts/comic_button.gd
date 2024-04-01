class_name ComicButton
extends RichTextLabel

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

#-------------------------------------------------------------------------------

var enabled: bool = true:
	set(value):
		enabled = value
		set_theme_override()

var hovered: bool = false:
	set(value):
		hovered = value
		set_theme_override()

var oid:int:
	get:
		return data.oid
	set(value):
		data.oid = value

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

#-------------------------------------------------------------------------------

func _init(_data:Dictionary, page:ComicPage):
	data = _data
	_default_data = _get_default_data()
	if not data.has("otype"):
		data.otype = "button"
	if not data.has("oid"):
		oid = page.make_oid()
	page.os[oid] = self
	if not data.has("text"):
		data.text = _default_data.text
	
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)
	bbcode_enabled = true
	fit_content = true
	# Buttons are in their own object so, unlike for elements in the page, there's no reason not to immediately apply the data.
	apply_data()

func apply_data():
	var s = "[center]"
	var padding_font_size:int = preload("res://theme/buttons_theme.tres").get_constant("padding_font_size", "RichTextLabel")
	if padding_font_size > 0:
		s += str("[font size=", padding_font_size, "] [/font]\n")
	s += data.text
	if padding_font_size > 0:
		s += str("\n[font size=", padding_font_size, "] [/font]")
	s += "[/center]"
	text = s


func _gui_input(event):
	if enabled and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and event.position.x > 0 and event.position.x < size.x and event.position.y > 0 and event.position.y < size.y:
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
		theme = preload("res://theme/button_disabled_theme.tres")
	else:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if hovered:
			theme = preload("res://theme/button_hover_theme.tres")
		else:
			theme = null

# ------------------------------------------------------------------------------

func _data_get(key:Variant):
	return data.get(key, _default_data[key])

func _data_set(key:Variant, value:Variant):
	if value == _default_data[key]:
		data.erase(key)
	else:
		data[key] = value

#TODO: Currently this doesn't need to be a method, and _default_data could be a const. If that doesn't change, fix it.
func _get_default_data() -> Dictionary:
	var r:Dictionary = {
		"text": "New Button",
		"action": Action.NEXT,
		"action_bookmark": "",
		"action_commands": "",
	}
	return r
