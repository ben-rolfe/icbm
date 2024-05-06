# Singleton name is Comic
extends Node

enum Overflow {
	SHOW,
	SCROLL,
	CLIP,
}


const DIR_STORY:String = "res://story/"
const DIR_FONTS:String = "res://library/fonts/"
const DIR_ICONS:String = "res://library/icons/"
const DEFAULT_BG:String = "res://theme/background.webp"

const IMAGE_EXT:PackedStringArray = ["webp", "png", "jpg", "jpeg", "svg"]

# These are used by balloons and tails at this point, but I think they're generic enough to go here.
const ROOT2:float = sqrt(2)
const QUARTIC2:float = sqrt(ROOT2)
const EDGE_SEGMENT_LENGTH:float = 4.0

# File versions are changed when the format is changed to something that isn't backwards compatible, and conversion is required.
const STORY_FILE_VERSION:int = 1
const SAVE_FILE_VERSION:int = 1

# The maximum code recursion depth for executing embedded code
const MAX_RECURSION = 50

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

const HORIZONTAL_ALIGNMENTS:Dictionary = {
	"Left":HORIZONTAL_ALIGNMENT_LEFT,
	"Center":HORIZONTAL_ALIGNMENT_CENTER,
	"Right":HORIZONTAL_ALIGNMENT_RIGHT,
}

#Regular expressions
#var _rex_bracketed_expressions:RegEx = RegEx.new()
var _rex_code_tags:RegEx = RegEx.new()
var _rex_code_tags_end:Dictionary = {}
var _rex_code_tags_separators:Dictionary = {}
var _rex_tag_params:RegEx = RegEx.new()
var _rex_escape_chars:RegEx = RegEx.new()
var _rex_sanitize_varname:RegEx = RegEx.new()

#These values are set in the root theme, under the Settings type. We store them on _init, for efficiency.
var _image_px_per_unit:float
var _units_in_width:float
var tail_width:float

var default_bg_path:String = ""

var book:ComicBook
var vars:Dictionary

var theme:Theme

var size:Vector2
var image_scale:float = 1
var px_per_unit:float = 1

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
#var _replacer_keys_ordered:Array[String] = []
var replacers:Dictionary = {}
var _code_tags:Dictionary = {}

var preset_properties:Dictionary = {
	"balloon": {
		"align": HORIZONTAL_ALIGNMENTS,
		"anchor": "vector2",
		"anchor_to": ANCHOR_POINTS,
		"bold": "bool",
		"bold_is_italic": "bool",
		"collapse": "bool",
		"content": "string",
		"edge_color": "color",
		"edge_style": "edge_style",
		"edge_thickness": "int",
		"font": "font",
		"font_color": "color",
		"fill_color": "color",
		"fragment": "string",
		"height": "int",
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
	"button": {
		"action": ComicButton.Action,
		"action_bookmark": "bookmark",
		"action_commands": "string",
		"content": "string",
		"fill_color": "color",
		"fill_color_disabled": "color",
		"fill_color_hovered": "color",
		"font_color": "color",
		"font_color_disabled": "color",
		"font_color_hovered": "color",
		"fragment": "string",
	},
	"kaboom": {
		"align": {
			"Left":HORIZONTAL_ALIGNMENT_LEFT,
			"Center":HORIZONTAL_ALIGNMENT_CENTER,
			"Right":HORIZONTAL_ALIGNMENT_RIGHT,
		},
		"anchor": "vector2",
		"bulge": "percent",
		"content": "string",
		"wave_period": "percent",
		"wave_height": "percent",
		"font": "font",
		"font_size": "percent",
		"font_color": "color",
		"fragment": "string",
		"grow": "percent",
		"layer": LAYERS,
		"outline_color": "color",
		"outline_thickness": "int",
		"rotate": "degrees",
		"rotate_chars": "bool",
		"spacing": "percent",
	},
	"line": {
		"edge_color": "color",
		"edge_width": "int",
		"fill_color": "color",
		"fill_width": "int",
		"fragment": "string",
		"layer": "int",
	},
	"note": {
		"anchor": "vector2",
		"content": "string",
		"fragment": "string",
		"layer": "int",
		"width": "int",
	},
}
var preset_property_misc_defaults = {
	"balloon": {
		"shape": "balloon",
		"edge_style": "smooth",
	},
}
var default_presets:Dictionary = {
	"balloon": {
		"" : {
			"align": HORIZONTAL_ALIGNMENT_CENTER,
			"bold_is_italic": true,
			"collapse": true,
			"content": "New Balloon...",
			"edge_thickness": 2,
			"fill_color": Color.WHITE,
			"layer": 2,
			"anchor_to": Vector2(0.5, 0.5),
			"squirk": 0.5,
			"width": 288,
		},
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
	"button": {
		"": {
			"action": ComicButton.Action.NEXT,
			"action_bookmark": "",
			"action_commands": "",
			"content": "New Button",
			"fill_color": Color.BLACK,
			"fill_color_disabled": Color(0.2, 0.2, 0.2),
			"fill_color_hovered": Color.BLACK,
			"font_color": Color.WHITE,
			"font_color_disabled": Color(0.6, 0.6, 0.6),
			"font_color_hovered": Color.YELLOW,
		},
	},
	"kaboom": {
		"": {
			"align": HORIZONTAL_ALIGNMENT_CENTER,
			"content": "Kaboom!",
			"font_color": Color.YELLOW,
			"layer": 4,
			"outline_color": Color.BLACK,
			"outline_thickness": 16,
			"rotate_chars": true,
			"wave_period": 2.0,
			"wave_height": 0.0,
		},
	},
	"line": {
		"": {
			"edge_color": Color.BLACK,
			"edge_width": 2,
			"fill_color": Color.WHITE,
			"fill_width": 8,
			"layer": 2,
		},
		"page_border": {
			"fill_width": 16,
		},
	},
	"note": {
		"": {
			"layer": 4,
			"width": 288,
		},
	},
}
var get_preset_options:Dictionary = {
	"shape": get_preset_options_shape,
	"edge_style": get_preset_options_edge_style,
}


func _init():
	theme = preload("res://theme/default.tres")
	size = Vector2(float(ProjectSettings["display/window/size/viewport_width"]), float(ProjectSettings["display/window/size/viewport_height"]))
	_units_in_width = theme.get_constant("units_in_width", "Settings")
	px_per_unit = float(size.x) / _units_in_width
	_image_px_per_unit = theme.get_constant("image_px_per_unit", "Settings")
	
	tail_width = theme.get_constant("tail_width", "Balloon")
	#Set up regular expressions
	recompile_rex_code_tags()
	# This regex, which is used for separating a tag's parameters, needs testing and, if possible, optimisation. (But it's broken my brain enough for now.) 
	#NOTE: It also doesn't allow for nested quotes of the same type, and has no way to escape them, which isn't ideal but I'm okay with it.
	_rex_tag_params.compile("[A-Za-z_]\\w*(\\s*=\\s*(([^\\\"\\']|\\\"[^\\\"]*\\\"|\\'[^\\']*\\')*?((?<=[\\\"\\'])|[^+\\-*\\/=\\(\\[\\{])(?=\\s+[A-Za-z_]|$)))?")
	_rex_escape_chars.compile("[\\\\\\.\\^\\$\\*\\+\\?\\(\\)\\[\\]\\{\\}\\|]")
	_rex_sanitize_varname.compile("[^a-zA-Z0-9_\\ ]")

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
	add_shape(ComicShape.new(), ComicEdgeStyle.new())
	add_edge_style(ComicBurstEdgeStyle.new())
	add_edge_style(ComicCloudEdgeStyle.new())
	add_edge_style(ComicDashEdgeStyle.new())
	add_edge_style(ComicRoughEdgeStyle.new())
	add_edge_style(ComicWobbleEdgeStyle.new())

	add_shape(ComicBoxShape.new(), ComicBoxEdgeStyle.new())
	add_edge_style(ComicBurstBoxEdgeStyle.new())
	add_edge_style(ComicCloudBoxEdgeStyle.new())
	add_edge_style(ComicDashBoxEdgeStyle.new())
	add_edge_style(ComicRoughBoxEdgeStyle.new())
	add_edge_style(ComicWobbleBoxEdgeStyle.new())

	add_tail_tip(ComicTailTip.new())
	add_tail_tip(ComicOpenTailTip.new())
	add_tail_tip(ComicArrowTailTip.new())
	add_tail_tip(ComicSquinkTailTip.new())

	add_tail_style(ComicTailStyle.new())
	add_tail_style(ComicCloudTailStyle.new())
	add_tail_style(ComicDashTailStyle.new())
	add_tail_style(ComicRoughTailStyle.new())
	add_tail_style(ComicWobbleTailStyle.new())
	add_tail_style(ComicZigTailStyle.new())
	add_tail_style(ComicZagTailStyle.new())

	#add_tag_replacer("b", _replace_b, true)
	#if theme.get_constant("replace_capital_i", "Settings") != 0:
		#var _regex_capital_i_in_word:RegEx = RegEx.new()
		#_regex_capital_i_in_word.compile("I(?=\\w)|(?<=\\w)I")
		#add_regex_replacer("capital_i_in_word", _regex_capital_i_in_word, _replace_capital_i_in_word)
		#add_tag_replacer("I", _replace_capital_i)
	#add_tag_replacer("br", _replace_br)
	#add_tag_replacer("tab", _replace_tab)
	#add_tag_replacer("tilde", _replace_tilde)
	#add_tag_replacer("-", _replace_hyphen)
	#add_tag_replacer("at", _replace_at)
	#add_tag_replacer("img", _replace_img, true)
	#add_tag_replacer("small", _replace_small, true)
	#var _regex_breath_marks:RegEx = RegEx.new()
	#_regex_breath_marks.compile("-\\)|\\(-")
	#add_regex_replacer("breath_marks", _regex_breath_marks, _replace_breath_marks)
	#var _regex_left_quotes:RegEx = RegEx.new()
	#_regex_left_quotes.compile("^[\\\"\\']|(?<=[\\s\\(\\{\\[\\]])[\\\"\\']")
	#add_regex_replacer("left_quotes", _regex_left_quotes, _replace_left_quotes)
	#var _regex_remaining_quotes:RegEx = RegEx.new()
	#_regex_remaining_quotes.compile("[\\\"\\']")
	#add_regex_replacer("remaining_quotes", _regex_remaining_quotes, _replace_remaining_quotes)

	add_code_tag("set", _code_tag_set)
	add_code_tag("if", _code_tag_if, true, "else")

	replacers["[b]"] = "[b][i]"
	replacers["[/b]"] = "[/i][/b]"
	var rex_capital_i_in_word:RegEx = RegEx.new()
	rex_capital_i_in_word.compile("I(?=\\w)|(?<=\\w)I")
	replacers[rex_capital_i_in_word] = "i"
	replacers["[I]"] = "I" # To allow author to force a capital I in a word.
	replacers["[br]"] = "\n"
	replacers["[tab]"] = "	"
	replacers["[tilde]"] = "~"
	replacers["at"] = "@"
	replacers["[-]"] = "‑" # Non-breaking hyphen (U+2011)
	replacers["-)"] = "⚞" # Left breath mark
	replacers["(-"] = "⚟" # Right breath mark
	var rex_lsq:RegEx = RegEx.new()
	rex_lsq.compile("^\\'|(?<=[\\s\\(\\{\\[\\]])\\'")
	replacers[rex_lsq] = "‘" # Left single-quote
	replacers["'"] = "’" # Right single-quote
	var rex_ldq:RegEx = RegEx.new()
	rex_ldq.compile("^\\\"|(?<=[\\s\\(\\{\\[\\]])\\\"")
	replacers[rex_ldq] = "“" # Left double-quote
	replacers["\""] = "”" # Right double-quote


# Escapes a string for use within a regex
func escape_regex(s:String) -> String:
	var matches:Array[RegExMatch] = _rex_escape_chars.search_all(s)
	var r:String = ""
	var pos:int = 0
	for match in matches:
		r = str(r, s.substr(pos, match.get_start() - pos), "\\")
		pos = match.get_start()
	r += s.substr(pos)
	return r

func add_shape(shape:ComicShape, default_edge_style:ComicEdgeStyle):
	assert(not shapes.has(shape.id), str("A shape with id '", shape.id, "' has already been added."))
	assert(shape.id == default_edge_style.shape_id, str("The default edge's shape_id (", default_edge_style.shape_id, ") must match the shape's id (", shape.id, ")"))
	shapes[shape.id] = shape
	edge_styles[shape.id] = {}
	add_edge_style(default_edge_style)

func get_shape(id:String) -> ComicShape:
	return shapes.get(id, shapes.values()[0])

func add_edge_style(edge_style:ComicEdgeStyle):
	assert(shapes.has(edge_style.shape_id), str("Cannot add edge style '", edge_style.id, "' to non-existent shape '", edge_style.shape_id, "'."))
	assert(not edge_styles[edge_style.shape_id].has(edge_style.id), str("An edge style with id '", edge_style.id, "' has already been added to shape '", edge_style.shape_id, "'."))
	edge_styles[edge_style.shape_id][edge_style.id] = edge_style

func get_edge_style(shape_id:String, id:String) -> ComicEdgeStyle:
	if not edge_styles.has(shape_id):
		return edge_styles.values()[0].values()[0]
	return edge_styles[shape_id].get(id, edge_styles[shape_id].values()[0])

func add_tail_tip(tail_tip:ComicTailTip):
	assert(not tail_tips.has(tail_tip.id), str("A tail end with id '", tail_tip.id, "' has already been added."))
	tail_tips[tail_tip.id] = tail_tip

func get_tail_tip(id:String) -> ComicTailTip:
	return tail_tips.get(id, tail_tips.values()[0])

func add_tail_style(tail_style:ComicTailStyle):
	assert(not tail_styles.has(tail_style.id), str("A tail style with id '", tail_style.id, "' has already been added."))
	tail_styles[tail_style.id] = tail_style

func get_tail_style(id:String) -> ComicTailStyle:
	return tail_styles.get(id, tail_styles.values()[0])

#func add_tag_replacer(key:String, callable:Callable, has_closing_tag:bool = false, separator_tags:Array[String] = [], add_before:String = ""):
	#assert(has_closing_tag or separator_tags == [], "A tag with separator tags must have a closing tag")
	#assert(not (key.contains("[") or key.contains("]")), "A tag replacer key may not contain \"[\" or \"]\" characters")
	#var replacer:Dictionary = {
		#"key": key,
		#"callable": callable,
		#"is_tag_replacer":true,
	#}
	#var escaped_key = escape_regex(key)
	#var regex = RegEx.new()
	#if has_closing_tag:
		#regex.compile(str("\\[(", escaped_key, ")(?:\\s+([^\\]]*))?\\]([\\s\\S]*?)\\[\\/", escaped_key, "\\]")) # the opening tag (the key in []s), parameters (capture group 1), content (capture group 2), the closing tag - parameters and content may be of 0 length
		#if separator_tags.size() > 0:
			#var regex_separators:RegEx = RegEx.new()
			#regex_separators.compile(str("\\[(", "|".join(separator_tags) ,")([^\\]]*)]"))
				##	([\s\S]*?)\[(elif|else)([^\]]*)] - works but messy
			#replacer.regex_separators = regex_separators
	#else:
		#regex.compile(str("\\[(", escaped_key, ")(?:\\s+([^\\]]*))?\\]()")) # the key in []s. Group 1: The tag key. Group 2: The params. Group 3: Empty, as this tag has no content.
##		regex.compile(str("\\[(", escaped_key, ")([^\\]]*)\\]()")) # the key in []s. Group 1: The tag key. Group 2: The params. Group 3: Empty, as this tag has no content.
	#replacer.regex = regex
	#_add_replacer(replacer, add_before)
#
#func add_regex_replacer(key:String, regex:RegEx, callable:Callable, regex_separators:RegEx = null, add_before:String = ""):
	#var replacer:Dictionary = {
		#"key": key,
		#"callable": callable,
		#"regex": regex,
	#}
	#if regex_separators != null:
		#replacer.regex_separators = regex_separators
	#_add_replacer(replacer, add_before)

#func add_replacer(key:Variant, value:String):
	#_replacers[key] = value
#
#func remove_replacer(key:String):
	#if _replacer_keys_ordered.has(key):
		#_replacers.erase(key)
		##_replacer_keys_ordered.erase(key)
#
func add_code_tag(key:String, f:Callable, has_closing_tag:bool = false, separator_tag:String = ""):
	_code_tags[key] = {"f": f}
	if has_closing_tag:
		#var rex_closing_string = str("\\[", key, "(?:\\s.*?)?\\].*?\\[\\/", key, ".*?\\]|\\[(\\/", key)
		var rex_closing_string = str("\\[(", key, "|\\/", key)
		if separator_tag != "":
			rex_closing_string = str(rex_closing_string, "|", separator_tag)
		rex_closing_string = str(rex_closing_string, ").*?]")
		_code_tags[key].rex_closing_tags = RegEx.new()
		_code_tags[key].rex_closing_tags.compile(rex_closing_string)
	recompile_rex_code_tags()

func remove_code_tag(key:String):
	_code_tags.erase(key)
	recompile_rex_code_tags()

func recompile_rex_code_tags():
	if _code_tags.size() == 0: # just [[raw code]]
		_rex_code_tags.compile("\\[\\[.*?\\]\\](?!\\])")
	else: # [[raw code]] or any [key] or [key some_parameters]
		var rex_string:String = "\\[(\\[.*?\\]|("
		var sep:String = ""
		for key in _code_tags:
			rex_string = str(rex_string, sep, key)
			sep = "|"
		rex_string = str(rex_string, ")(\\s.*?)?)\\](?!\\])")
		_rex_code_tags.compile(rex_string)

#func _add_replacer(replacer:Dictionary, add_before:String):
	#assert(not _replacers.has(replacer.key), str("You cannot add a replacer with the key '", replacer.key , "' because one already exists. Try removing it with Comic.remove_replacer first."))
	#_replacers[replacer.key] = replacer
	#var add_before_pos:int = _replacer_keys_ordered.find(add_before)
	#if add_before_pos > -1:
		#_replacer_keys_ordered.insert(add_before_pos, replacer.key)
	#else:
		#_replacer_keys_ordered.push_back(replacer.key)

func execute(command: String) -> Variant:
	#if Comic.book is ComicEditor:
		## We don't execute code in the editor - we display it.
		#return str("[bgcolor=#ccc]", command, "[/bgcolor]")

	print("Executing ", command, " as ", command.replace("~", "vars."))
	var expression = Expression.new()
	var error = expression.parse(command.replace("~", "vars."), ["vars"])
	if error != OK:
		print(expression.get_error_text())
		push_error(expression.get_error_text())
		return "<<Error>>"
	var result = expression.execute([Comic.vars])
	if expression.has_execute_failed():
		# We don't need to push an error - that already happened when we tried to execute.
#		push_error("Error in executed string. No more information is available. Check your spelling, that variables are preceded by ~ and exist in Comic.vars, and that strings are encapsulated in quote marks.")
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

#func execute_embedded_code(s:String) -> String:
	#var r:String
	#var last_end:int = 0
	#for result in _rex_bracketed_expressions.search_all(s):
		## Add the preceding unprocessed part to the return value, then the processed text between the brackets
		#r = str(r, s.substr(last_end, result.get_start() - last_end), execute(result.get_string().substr(2, result.get_string().length() - 4)))
		#last_end = result.get_end()
	#r = str(r, s.substr(last_end))
	#return r

func execute_embedded_code(s:String, depth:int = 0) -> String:
	print("Executing embedded code: ", s)
	if depth > MAX_RECURSION:
		push_error("Too much recursion in embedded code - failing on: ", s)
		return ""
	var r:String
	var length:int = s.length()
	var offset:int = 0
	var finished:bool = false
	while not finished:
		var rex_match = _rex_code_tags.search(s, offset)
		if rex_match == null:
			# No matches left - just add what's left of the input string to the return string
			print("No matches left")
			r = str(r, s.substr(offset))
			finished = true
		else:
			print("Regex match!")
			#Add all content before the match to the return string
			r = str(r, s.substr(offset, rex_match.get_start() - offset))
			print(rex_match.strings)
			if rex_match.strings[1][0] == "[":
				# This is double-bracketed raw code. index 1 is the match with one set of brackets - we need to strip them off and execute the contents
				print("Raw code: ", rex_match.strings[1].substr(1, rex_match.strings[1].length() - 2))
				print(Comic.vars)
				r = str(r, execute(rex_match.strings[1].substr(1, rex_match.strings[1].length() - 2)))
				offset = rex_match.get_end()
			else:
				# This is a code tag.
				# index 0 is the whole contents of the tag, including the brackets
				# index 1 is the whole contents of the tag, without the brackets
				# index 2 is the tag name
				# index 3 is the parameters string (beginning with at least one character of whitespace)
				#NOTE: We recursively call execute_embedded code on the results of tag functions.
				offset = rex_match.get_end()
				var key:String = rex_match.strings[2]
				var params = parameterize(rex_match.strings[3])
				
				print("Tag found! ")
				if _code_tags[key].has("rex_closing_tags"):
					print("With closing tags")
					var nest_level:int = 0
					var contents:Array = []
					for closing_match in _code_tags[key].rex_closing_tags.search_all(s, offset):
						print("BEFORE ", nest_level, ": ", closing_match.strings[1])
						if closing_match.strings[1] == key:
							# opening tag - increase nesting level
							nest_level += 1
						else:
							if nest_level == 0:
								# We're on the base level, so the tag splits the content
								contents.push_back(s.substr(offset, closing_match.get_start() - offset))
								offset = closing_match.get_end()
							if closing_match.strings[1] == str("/", key):
								# Closing tag, not a separator
								nest_level -= 1
								if nest_level < 0:
									break
					r = str(r, execute_embedded_code(_code_tags[key].f.call(params, contents), depth + 1))
				else:
					r = str(r, execute_embedded_code(_code_tags[key].f.call(params), depth + 1))
			if offset >= length:
				finished = true
	#var last_end:int = 0
	#for result in _rex_bracketed_expressions.search_all(s):
		## Add the preceding unprocessed part to the return value, then the processed text between the brackets
		#r = str(r, s.substr(last_end, result.get_start() - last_end), execute(result.get_string().substr(2, result.get_string().length() - 4)))
		#last_end = result.get_end()
	#r = str(r, s.substr(last_end))
	return r

func parameterize(s:String) -> Dictionary:
	var r:Dictionary = { "":s.strip_edges() }
	for rex_match in _rex_tag_params.search_all(r[""]):
		var pair = rex_match.get_string().split("=", false, 1)
		r[pair[0].strip_edges()] = true if pair.size() == 1 else pair[1].strip_edges()
	return r

func style_embedded_code(s:String) -> String:
	var r:String
	var last_end:int = 0
	for result in _rex_code_tags.search_all(s):
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
	for key in replacers:
		if key is RegEx:
			# Regex replacement
			r = key.sub(r, replacers[key], true)
		else:
			# String replacement
			r = r.replace(key, replacers[key])
	if r == "":
		r = " " # This is to ensure that empty speech balloons in the editor don't disappear entirely
	return r

func parse_bool_string(s: String) -> bool:
	s = s.strip_edges().to_lower()
	return s == "true" or s == "yes" or s == "1"


#func replacer_execute(s:String, replacer:Dictionary) -> String:
	#var matches:Array[RegExMatch] = replacer.regex.search_all(s)
	#var pos:int = 0
	#var r = ""
	#for match in matches:
		#r += s.substr(pos, match.get_start() - pos)
		#if replacer.has("is_tag_replacer"):
			#r += replacer.callable.call({
				#"tag": match.strings[1],
				#"params": split_tag_params(match.strings[2]),
				#"content": match.strings[3],
			#})
		#else:
			#r += replacer.callable.call(match)
		#pos = match.get_end()
	#r += s.substr(pos)
	#return r

func split_tag_params(s:String) -> Dictionary:
	var r:Dictionary = {}
	for match in _rex_tag_params.search_all(s):
		r[match.strings[1]] = match.strings[2]
	return r

# ------------------------------------------------------------------------------
# Tag methods
# ------------------------------------------------------------------------------
#func _replace_b(match_dict:Dictionary) -> String:
	## Catches [b] and replaces it with [b][/i], unless plain is specified
	#if match_dict.params.has("plain"):
		#return str("[b]", match_dict.content, "[/b]")
	#else:
		#return str("[b][i]", match_dict.content, "[/i][/b]")
#
#func _replace_br(_match_dict:Dictionary) -> String:
	#return "\n"
#
#func _replace_tab(_match_dict:Dictionary) -> String:
	#return "	"
#
#func _replace_tilde(_match_dict:Dictionary) -> String:
	#return "~"
#
#func _replace_at(_match_dict:Dictionary) -> String:
	#return "@"
#
#func _replace_hyphen(_match_dict:Dictionary) -> String:
	#return "‑" # Non-Hreaking Hyphen U+2011
#
#func _replace_capital_i(_match_dict:Dictionary) -> String:
	#return "I"
#
#func _replace_capital_i_in_word(_regex_match:RegExMatch) -> String:
	#return "i"
#
#func _replace_left_quotes(regex_match:RegExMatch) -> String:
	#return "‘" if regex_match.strings[0] == "'" else "“"
#
#func _replace_remaining_quotes(regex_match:RegExMatch) -> String:
	#return "’" if regex_match.strings[0] == "'" else "”"
#
#func _replace_breath_marks(regex_match:RegExMatch) -> String:
	#return "⚞" if regex_match.strings[0] == "-)" else "⚟"
#
#func _replace_small(match_dict:Dictionary) -> String:
	#return str("[font size=", theme.get_font_size("normal_font_size", "RichTextLabel") * theme.get_constant("small_scale", "Balloon") / 100.0, "]", match_dict.content, "[/font]")
#
#func _replace_img(match_dict:Dictionary) -> String:
	#var s = "[img"
	#for key in match_dict.params.keys():
		#s = str(s, " ", key, "=", match_dict.params[key])
	#s = str(s, "]")
	#if match_dict.content.left(6) == "res://":
		## Absolute file path. Don't do anything with it.
		#s = str(s, match_dict.content)
	#else:
		## Relative file path
		#var found:bool = false
		#for ext in IMAGE_EXT:
			#var path:String = str("res://images/", match_dict.content, ".", ext)
			#if ResourceLoader.exists(path):
				#found = true
				#s = str(s, path)
				#break
		#if not found:
			#return "<Image not found>"
	#s = str(s, "[/img]")
	#return s

# ------------------------------------------------------------------------------

func validate_name(s:String) -> String:
	s = s.replace("-", "_")
	s = _rex_sanitize_varname.sub(s, "", true).to_lower().to_snake_case()
	s = s.lstrip("_").rstrip("_")
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

func get_preset_data(category:String, chosen_presets:Array = []) -> Dictionary:
	var r = {}
	for key in preset_properties[category]:
		var value:Variant = _get_preset_default(category, key)
		if value != null:
			r[key] = value

	# We iterate over the full list of known presets, rather than the presets array, because we want to apply presets in the order they appear in that list.
	# Also, we want to add the "" default preset.
	for preset_key in Comic.book.presets[category].keys():
		if preset_key == "" or chosen_presets.has(preset_key):
			# We have this preset - apply all its keys to the default data 
			for key in Comic.book.presets[category][preset_key].keys():
				r[key] = Comic.book.presets[category][preset_key][key]
	return r

func _get_preset_default(category:String, key:Variant) -> Variant:
	if preset_property_misc_defaults.has(category) and preset_property_misc_defaults[category].has(key):
		return Comic.preset_property_misc_defaults[category][key]
	elif preset_properties[category][key] is Dictionary and preset_properties[category][key].size() > 0:
		return Comic.preset_properties[category][key].values()[0]
	elif Comic.preset_properties[category][key] is Array and preset_properties[category][key].size() > 0:
		return 0
	else:
		match(Comic.preset_properties[category][key]):
			"bookmark":
				return "start"
			"bool":
				return false
			"color":
				return Color.BLACK
			"degrees", "int":
				return 0
			"font":
				return "default"
			"percent":
				return 1.0
			"string":
				return ""
			"vector2":
				return Vector2.ZERO
	return null
	
func get_preset_options_shape() -> Array:
	return shapes.keys()

func get_preset_options_edge_style() -> Array:
	var r:Array = []
	for shape in shapes:
		for edge_style in edge_styles[shape]:
			if not r.has(edge_style):
				r.push_back(edge_style)
	return r

#NOTE: This function modifies the passed array! The array is then also returned so that it can be conveniently used in-line.
func natural_sort(array:Array) -> Array:
	array.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	return array

#NOTE: This function DOESN'T modify the passed dictionary, like natural_sort does with arrays.
func sort_dictionary(unsorted:Dictionary) -> Dictionary:
	var sorted:Dictionary = {}
	var keys:Array = unsorted.keys()
	natural_sort(keys)
	for key in keys:
		sorted[key] = unsorted[key]
	return sorted


func _code_tag_set(params:Dictionary) -> String:
	for key in params:
		if key != "":
			if key[0] == "~": # Remove the optional tilde
				key = key.substr(1)
			vars[key] = execute(params[key])
	return ""

func _code_tag_if(params:Dictionary, contents:Array) -> String:
	print("IF!")
	print(contents)
	if execute(params[""]):
		return contents[0]
	elif contents.size() > 1:
		return contents[1]
	return ""
