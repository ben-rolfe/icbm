class_name ComicButton
extends RichTextLabel

var click_lines:Array[String] = []
var enabled: bool = true:
	set(value):
		enabled = value
		set_theme_override()
var hovered: bool = false:
	set(value):
		hovered = value
		set_theme_override()
var key_string:String

func _init(params:Dictionary):
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)
	bbcode_enabled = true
	fit_content = true
	var s = "[center]"
	var padding_font_size:int = preload("res://theme/buttons_theme.tres").get_constant("padding_font_size", "RichTextLabel")
	if padding_font_size > 0:
		s += str("[font size=", padding_font_size, "] [/font]\n")
	s += Comic.parse_rich_text_string(str(params[0]))
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
	if Comic.book is ComicEditor:
		print("Edit Mode")
	else:
		Comic.book.read_lines(click_lines, self)

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
