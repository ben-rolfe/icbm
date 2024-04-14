# Class name is Comic, granted by AutoLoad rather than class_name
extends Node

enum Overflow {
	SHOW,
	SCROLL,
	CLIP,
}


const DIR_STORY:String = "res://story/"
const DIR_FONTS:String = "res://theme/fonts/"
const DEFAULT_BG:String = "res://theme/background.webp"

const IMAGE_EXT:PackedStringArray = ["webp", "png", "jpg", "jpeg", "svg"]

# These are used by balloons and tails at this point, but I think they're generic enough to go here.
const ROOT2:float = sqrt(2)
const QUARTIC2:float = sqrt(ROOT2)
const EDGE_SEGMENT_LENGTH:float = 4.0

var LAYERS:Array[String] = [
	"Furthest",
	"Further",
	"Middle",
	"Closer",
	"Closest",
]

const ANCHOR_POINTS = {
	"TL":Vector2(0, 0),
	"T":Vector2(0, 0.5),
	"TR":Vector2(0, 1),
	"L":Vector2(0.5, 0),
	"C":Vector2(0.5, 0.5),
	"R":Vector2(0.5, 1),
	"BL":Vector2(1, 0),
	"B":Vector2(1, 0.5),
	"BR":Vector2(1, 1),
}


#Regular expressions
var _rex_bracketed_expressions:RegEx = RegEx.new()
var _regex_tag_params:RegEx = RegEx.new()
var _regex_escape_chars:RegEx = RegEx.new()
var _regex_sanitize_varname:RegEx = RegEx.new()

#These values are set in the root theme, under the Settings type. We store them on _init, for efficiency.
var _image_px_per_unit:float
var _units_in_width:float
var tail_width:float

var default_bg_path:String = ""

var book:ComicBook

var theme:Theme
var size:Vector2

var shapes:Dictionary = {}
var edge_styles:Dictionary = {}
var tail_tips:Dictionary = {}
var tail_styles:Dictionary = {}

# These are ComicScript language constructs, rather than callable commands - we put them in the _commands dictionary to stop people from adding a command of the same name (which would be ignored without error, otherwise)
var commands:Dictionary = {
	"*": null, 
	"+": null, 
	"set": null,
	"if": null, "while": null, 
	"else": null, "elif": null,
}
var _replacer_keys_ordered:Array[String] = []
var _replacers:Dictionary = {}

var image_scale:float = 1

var px_per_unit:float = 1

var preset_properties:Dictionary = {
	"balloon": {
		"align": {
			"Left":HORIZONTAL_ALIGNMENT_LEFT,
			"Center":HORIZONTAL_ALIGNMENT_CENTER,
			"Right":HORIZONTAL_ALIGNMENT_RIGHT,
		},
		"anchor": "hidden",
		"anchor_to": ANCHOR_POINTS,
		"bold": "bool",
		"bold_is_italic": "bool",
		"collapse": "bool",
		"edge_color": "color",
		"edge_style": "edge_style",
		"edge_thickness": "int",
		"height": "int",
		"font": "font",
		"font_color": "color",
		"fill_color": "color",
		"italic": "bool",
		"layer": LAYERS,
		"scale_all": "percent",
		"scale_box": "percent",
		"scale_edge_h": "percent",
		"scale_edge_w": "percent",
		"scale_font": "percent",
		"scroll": "bool",
		"shape": "shape",
		"squirk": "percent",
		"width": "int",
	},
	"kaboom": {

		"align": {
			"Left":HORIZONTAL_ALIGNMENT_LEFT,
			"Center":HORIZONTAL_ALIGNMENT_CENTER,
			"Right":HORIZONTAL_ALIGNMENT_RIGHT,
		},
		"anchor": "hidden",
		"bulge": "percent",
		"wave_period": "percent",
		"wave_height": "percent",
		"font": "font",
		"font_size": "percent",
		"font_color": "color",
		"grow": "percent",
		"layer": LAYERS,
		"outline_color": "color",
		"outline_thickness": "int",
		"rotate": "degrees",
		"rotate_chars": "bool",
		"spacing": "percent",
		
	},
}
var default_presets:Dictionary = {
	"balloon": {
		"caption": {
			"shape": "box",
			"italic": true,
			"fill_color": Color(1,1,0.6),
			"anchor_to": Vector2.ZERO
		},
		"thought": {
			"edge_style": "cloud",
			"italic": true,
		},
		"whisper": {
			"edge_style": "dash",
			"italic": true,
			"text_scale": 0.75,
		},
		"yell": {
			"edge_style": "burst",
			"bold": true,
		},
	},
	"kaboom": {}
}


func _init():
	theme = preload("res://theme/root_theme.tres")
	size = Vector2(float(ProjectSettings["display/window/size/viewport_width"]), float(ProjectSettings["display/window/size/viewport_height"]))
	_units_in_width = theme.get_constant("units_in_width", "Settings")
	px_per_unit = float(size.x) / _units_in_width
	_image_px_per_unit = theme.get_constant("image_px_per_unit", "Settings")
	
	tail_width = theme.get_constant("tail_width", "Balloon")
	#Set up regular expressions
	_rex_bracketed_expressions.compile("\\[\\[.*?\\]\\]") # finds terms contained in double square brackets.
	#_rex_left_single_quotes.compile("^\\'|(?<=[\\s\\(\\{\\[])\\'")
	#_rex_left_double_quotes.compile('^\\"|(?<=[\\s\\(\\{\\[])\\"')
	# Attempt at a better regex that isn't quite there: ^\'|(?<=[\s\(\{\[])(?:\[[^\]]*\])*\'
	_regex_tag_params.compile("(\\w+)(?:\\s*=\\s*(\\\"[^\\\"]*\\\"|[^\\s]*))?")
	_regex_escape_chars.compile("[\\\\\\.\\^\\$\\*\\+\\?\\(\\)\\[\\]\\{\\}\\|]")
	_regex_sanitize_varname.compile("[^a-zA-Z0-9_\\ ]")

	for ext in IMAGE_EXT:
		var path: String = str("res://theme/background.", ext)
		if ResourceLoader.exists(path):
			default_bg_path = path
			var bg_texture:Texture2D = load(path)
			image_scale = size.x / bg_texture.get_width()
			var image_scale_h = size.y / bg_texture.get_height()
			assert(image_scale == image_scale_h, "The background image must be the same ratio as the viewport width set in the project settings")
			break
	assert(default_bg_path != "", "A default background must be supplied at res://theme/background.webp (or other valid image file extension)")

func _ready():
	register_shape(ComicShape.new(), ComicEdgeStyle.new())
	register_edge_style(ComicBurstEdgeStyle.new())
	register_edge_style(ComicCloudEdgeStyle.new())
	register_edge_style(ComicDashEdgeStyle.new())
	register_edge_style(ComicRoughEdgeStyle.new())
	register_edge_style(ComicWobbleEdgeStyle.new())

	register_shape(ComicBoxShape.new(), ComicBoxEdgeStyle.new())
	register_edge_style(ComicBurstBoxEdgeStyle.new())
	register_edge_style(ComicCloudBoxEdgeStyle.new())
	register_edge_style(ComicDashBoxEdgeStyle.new())
	register_edge_style(ComicRoughBoxEdgeStyle.new())
	register_edge_style(ComicWobbleBoxEdgeStyle.new())

	register_tail_tip(ComicTailTip.new())
	register_tail_tip(ComicOpenTailTip.new())
	register_tail_tip(ComicArrowTailTip.new())
	register_tail_tip(ComicSquinkTailTip.new())

	register_tail_style(ComicTailStyle.new())
	register_tail_style(ComicCloudTailStyle.new())
	register_tail_style(ComicDashTailStyle.new())
	register_tail_style(ComicRoughTailStyle.new())
	register_tail_style(ComicWobbleTailStyle.new())
	register_tail_style(ComicZigTailStyle.new())
	register_tail_style(ComicZagTailStyle.new())

	add_tag_replacer("b", _replace_b, true)
	if theme.get_constant("replace_capital_i", "Settings") != 0:
		var _regex_capital_i_in_word:RegEx = RegEx.new()
		_regex_capital_i_in_word.compile("I(?=\\w)|(?<=\\w)I")
		add_regex_replacer("capital_i_in_word", _regex_capital_i_in_word, _replace_capital_i_in_word)
		add_tag_replacer("I", _replace_capital_i)
	add_tag_replacer("br", _replace_br)
	add_tag_replacer("tab", _replace_tab)
	add_tag_replacer("tilde", _replace_tilde)
	add_tag_replacer("-", _replace_hyphen)
	add_tag_replacer("at", _replace_at)
	add_tag_replacer("img", _replace_img, true)
	add_tag_replacer("small", _replace_small, true)
	var _regex_breath_marks:RegEx = RegEx.new()
	_regex_breath_marks.compile("-\\)|\\(-")
	add_regex_replacer("breath_marks", _regex_breath_marks, _replace_breath_marks)
	var _regex_left_quotes:RegEx = RegEx.new()
	_regex_left_quotes.compile("^[\\\"\\']|(?<=[\\s\\(\\{\\[\\]])[\\\"\\']")
	add_regex_replacer("left_quotes", _regex_left_quotes, _replace_left_quotes)
	var _regex_remaining_quotes:RegEx = RegEx.new()
	_regex_remaining_quotes.compile("[\\\"\\']")
	add_regex_replacer("remaining_quotes", _regex_remaining_quotes, _replace_remaining_quotes)

# Escapes a string for use within a regex
func escape_regex(s:String) -> String:
	var matches:Array[RegExMatch] = _regex_escape_chars.search_all(s)
	var r:String = ""
	var pos:int = 0
	for match in matches:
		r = str(r, s.substr(pos, match.get_start() - pos), "\\")
		pos = match.get_start()
	r += s.substr(pos)
	return r

func register_shape(shape:ComicShape, default_edge_style:ComicEdgeStyle):
	assert(not shapes.has(shape.id), str("A shape with id '", shape.id, "' has already been registered."))
	assert(shape.id == default_edge_style.shape_id, str("The default edge's shape_id (", default_edge_style.shape_id, ") must match the shape's id (", shape.id, ")"))
	shapes[shape.id] = shape
	edge_styles[shape.id] = {}
	register_edge_style(default_edge_style)

func get_shape(id:String) -> ComicShape:
	return shapes.get(id, shapes.values()[0])

func register_edge_style(edge_style:ComicEdgeStyle):
	assert(shapes.has(edge_style.shape_id), str("Cannot register edge style '", edge_style.id, "' to non-existent shape '", edge_style.shape_id, "'."))
	assert(not edge_styles[edge_style.shape_id].has(edge_style.id), str("An edge style with id '", edge_style.id, "' has already been registered to shape '", edge_style.shape_id, "'."))
	edge_styles[edge_style.shape_id][edge_style.id] = edge_style

func get_edge_style(shape_id:String, id:String) -> ComicEdgeStyle:
	if not edge_styles.has(shape_id):
		return edge_styles.values()[0].values()[0]
	return edge_styles[shape_id].get(id, edge_styles[shape_id].values()[0])

func register_tail_tip(tail_tip:ComicTailTip):
	assert(not tail_tips.has(tail_tip.id), str("A tail end with id '", tail_tip.id, "' has already been registered."))
	tail_tips[tail_tip.id] = tail_tip

func get_tail_tip(id:String) -> ComicTailTip:
	return tail_tips.get(id, tail_tips.values()[0])

func register_tail_style(tail_style:ComicTailStyle):
	assert(not tail_styles.has(tail_style.id), str("A tail style with id '", tail_style.id, "' has already been registered."))
	tail_styles[tail_style.id] = tail_style

func get_tail_style(id:String) -> ComicTailStyle:
	return tail_styles.get(id, tail_styles.values()[0])



func add_tag_replacer(key:String, callable:Callable, has_closing_tag:bool = false, separator_tags:Array[String] = [], register_before:String = ""):
	assert(has_closing_tag or separator_tags == [], "A tag with separator tags must have a closing tag")
	assert(not (key.contains("[") or key.contains("]")), "A tag replacer key may not contain \"[\" or \"]\" characters")
	var replacer:Dictionary = {
		"key": key,
		"callable": callable,
		"is_tag_replacer":true,
	}
	var escaped_key = escape_regex(key)
	var regex = RegEx.new()
	if has_closing_tag:
		regex.compile(str("\\[(", escaped_key, ")(?:\\s+([^\\]]*))?\\]([\\s\\S]*?)\\[\\/", escaped_key, "\\]")) # the opening tag (the key in []s), parameters (capture group 1), content (capture group 2), the closing tag - parameters and content may be of 0 length
		if separator_tags.size() > 0:
			var regex_separators:RegEx = RegEx.new()
			regex_separators.compile(str("\\[(", "|".join(separator_tags) ,")([^\\]]*)]"))
				#	([\s\S]*?)\[(elif|else)([^\]]*)] - works but messy
			replacer.regex_separators = regex_separators
	else:
		regex.compile(str("\\[(", escaped_key, ")(?:\\s+([^\\]]*))?\\]()")) # the key in []s. Group 1: The tag key. Group 2: The params. Group 3: Empty, as this tag has no content.
#		regex.compile(str("\\[(", escaped_key, ")([^\\]]*)\\]()")) # the key in []s. Group 1: The tag key. Group 2: The params. Group 3: Empty, as this tag has no content.
	replacer.regex = regex
	_add_replacer(replacer, register_before)

func add_regex_replacer(key:String, regex:RegEx, callable:Callable, regex_separators:RegEx = null, register_before:String = ""):
	var replacer:Dictionary = {
		"key": key,
		"callable": callable,
		"regex": regex,
	}
	if regex_separators != null:
		replacer.regex_separators = regex_separators
	_add_replacer(replacer, register_before)

func remove_replacer(key:String):
	if _replacer_keys_ordered.has(key):
		_replacers.erase(key)
		_replacer_keys_ordered.erase(key)

func _add_replacer(replacer:Dictionary, register_before:String):
	assert(not _replacers.has(replacer.key), str("You cannot add a replacer with the key '", replacer.key , "' because one already exists. Try removing it with Comic.remove_replacer first."))
	_replacers[replacer.key] = replacer
	var register_before_pos:int = _replacer_keys_ordered.find(register_before)
	if register_before_pos > -1:
		_replacer_keys_ordered.insert(register_before_pos, replacer.key)
	else:
		_replacer_keys_ordered.push_back(replacer.key)

func execute(command: String) -> Variant:
	if Comic.book is ComicEditor:
		# We don't execute code in the editor - we display it.
		return str("[bgcolor=#ccc]", command, "[/bgcolor]")

	#print("Executing ", command)
	var expression = Expression.new()
	# We split by the tilde escape sequence, replace all tildes with references to the vars object, then join with the escaped tildes
	var command_parts = command.split("~~")
	for i in command_parts.size():
		command_parts[i] = command_parts[i].replace("~", "vars.")
	#print("as ", "~".join(command_parts))
	var error = expression.parse("~".join(command_parts), ["vars"])
	if error != OK:
		push_error(expression.get_error_text())
		return "<<Error>>"
	var result = expression.execute([book.vars])
	if expression.has_execute_failed():
		push_error("Error in executed string. No more information is available. Check your spelling and that strings are encapsulated in quote marks.")
		return "<Error>"
	#print("Returning ", result)
	return result


func load_texture(path:String, dir:String = DIR_STORY) -> Texture2D:
	for ext in IMAGE_EXT:
		var full_path: String = str(dir, path, ".", ext)
		if ResourceLoader.exists(full_path):
			return ResourceLoader.load(full_path)
#	push_warning("Image failed to load from path: ", path)
	return null

func execute_embedded_code(s:String) -> String:
	var r:String
	var last_end:int = 0
	for result in _rex_bracketed_expressions.search_all(s):
		# Add the preceding unprocessed part to the return value, then the processed text between the brackets
		r = str(r, s.substr(last_end, result.get_start() - last_end), execute(result.get_string().substr(2, result.get_string().length() - 4)))
		last_end = result.get_end()
	r = str(r, s.substr(last_end))
	return r

func style_embedded_code(s:String) -> String:
	var r:String
	var last_end:int = 0
	for result in _rex_bracketed_expressions.search_all(s):
		# Add the preceding unprocessed part to the return value, then the processed text between the brackets
		r = str(r, s.substr(last_end, result.get_start() - last_end), "[bgcolor=#ccc][color=#333]", result.get_string().substr(2, result.get_string().length() - 4), "[/color][/bgcolor]")
		last_end = result.get_end()
	r = str(r, s.substr(last_end))
	return r

func parse_hidden_string(s:String):
	if OS.is_debug_build():
		print(execute_embedded_code(s))
	else:
		execute_embedded_code(s)

func parse_rich_text_string(s: String) -> String:
	# In the editor we'll have un-executed code that we want to style.
	var r:String = style_embedded_code(s) if Comic.book is ComicEditor else s
	for key in _replacer_keys_ordered:
		r = replacer_execute(r, _replacers[key])
	if r == "":
		r = " "
	return r

func replacer_execute(s:String, replacer:Dictionary) -> String:
	var matches:Array[RegExMatch] = replacer.regex.search_all(s)
	var pos:int = 0
	var r = ""
	for match in matches:
		r += s.substr(pos, match.get_start() - pos)
		if replacer.has("is_tag_replacer"):
			r += replacer.callable.call({
				"tag": match.strings[1],
				"params": split_tag_params(match.strings[2]),
				"content": match.strings[3],
			})
		else:
			r += replacer.callable.call(match)
		pos = match.get_end()
	r += s.substr(pos)
	return r

func split_tag_params(s:String) -> Dictionary:
	var r:Dictionary = {}
	for match in _regex_tag_params.search_all(s):
		r[match.strings[1]] = match.strings[2]
	return r

# ------------------------------------------------------------------------------
# Tag methods
# ------------------------------------------------------------------------------
func _replace_b(match_dict:Dictionary) -> String:
	# Catches [b] and replaces it with [b][/i], unless plain is specified
	if match_dict.params.has("plain"):
		return str("[b]", match_dict.content, "[/b]")
	else:
		return str("[b][i]", match_dict.content, "[/i][/b]")

func _replace_br(_match_dict:Dictionary) -> String:
	return "\n"

func _replace_tab(_match_dict:Dictionary) -> String:
	return "	"

func _replace_tilde(_match_dict:Dictionary) -> String:
	return "~"

func _replace_at(_match_dict:Dictionary) -> String:
	return "@"

func _replace_hyphen(_match_dict:Dictionary) -> String:
	return "‑" # Non-Hreaking Hyphen U+2011

func _replace_capital_i(_match_dict:Dictionary) -> String:
	return "I"

func _replace_capital_i_in_word(_regex_match:RegExMatch) -> String:
	return "i"

func _replace_left_quotes(regex_match:RegExMatch) -> String:
	return "‘" if regex_match.strings[0] == "'" else "“"

func _replace_remaining_quotes(regex_match:RegExMatch) -> String:
	return "’" if regex_match.strings[0] == "'" else "”"

func _replace_breath_marks(regex_match:RegExMatch) -> String:
	return "⚞" if regex_match.strings[0] == "-)" else "⚟"

func _replace_small(match_dict:Dictionary) -> String:
	return str("[font size=", theme.get_font_size("normal_font_size", "RichTextLabel") * theme.get_constant("small_scale", "Balloon") / 100.0, "]", match_dict.content, "[/font]")

func _replace_img(match_dict:Dictionary) -> String:
	var s = "[img"
	for key in match_dict.params.keys():
		s = str(s, " ", key, "=", match_dict.params[key])
	s = str(s, "]")
	if match_dict.content.left(6) == "res://":
		# Absolute file path. Don't do anything with it.
		s = str(s, match_dict.content)
	else:
		# Relative file path
		var found:bool = false
		for ext in IMAGE_EXT:
			var path:String = str("res://images/", match_dict.content, ".", ext)
			if ResourceLoader.exists(path):
				found = true
				s = str(s, path)
				break
		if not found:
			return "<Image not found>"
	s = str(s, "[/img]")
	return s

# ------------------------------------------------------------------------------

func validate_name(s:String) -> String:
	s = s.replace("-", "_")
	s = _regex_sanitize_varname.sub(s, "", true).to_lower().to_snake_case()
	s = s.lstrip("_").rstrip("_")
	if s == "":
		s = "a"
	return s
	
func request_quit():
	if book.has_unsaved_changes:
		confirm("Discard Changes?", "You have unsaved changes.\n\nIf you quit, they will be lost.\n\nAre you sure you want to quit?", quit)
	else:
		quit()

func quit():
	get_tree().quit()

func get_seed_from_position(v:Vector2) -> int:
	return int(v.x + v.y * size.x)

func alert(title:String, text:String, callback:Callable = Callable()):
	confirm(title, text, callback, "OK", "")

func confirm(title:String, text:String, confirm_callback:Callable = Callable(), confirm_text:String = "Yes", cancel_text:String = "No", cancel_callback:Callable = Callable()):
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = text
	dialog.ok_button_text = confirm_text
	dialog.confirmed.connect(dialog.queue_free)
	dialog.confirmed.connect(confirm_callback)
	if cancel_text != "":
		dialog.add_cancel_button(cancel_text)
		dialog.canceled.connect(dialog.queue_free)
		dialog.canceled.connect(cancel_callback)
	add_child(dialog)
	dialog.popup_centered()

#
#You can use the OS / platform's alert system:
#
#OS.alert('This is your message', 'Message Title')
#
#You can use WindowDialog or subclass on any node like this:
#
#func alert(text: String, title: String='Message') -> void:
	#var dialog = AcceptDialog.new()
	#dialog.dialog_text = text
	#dialog.window_title = title
	#dialog.connect('modal_closed', dialog, 'queue_free')
	#add_child(dialog)
	#dialog.popup_centered()
#
#You can do the above, but globally:
#
#func alert(text: String, title: String='Message') -> void:
	## ... code from above, but instead of `add_child(dialog)` do
	#var scene_tree = Engine.get_main_loop()
	#scene_tree.current_scene.add_child(dialog)
	#dialog.popup_centered()
#
