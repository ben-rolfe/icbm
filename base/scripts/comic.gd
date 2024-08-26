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
const DIR_IMAGES:String = "res://library/images/"
const DIR_SAVES:String = "user://saves/"
const DIR_SCREENSHOTS:String = "user://screenshots/"
const CONFIG_FILE:String = "user://config.cfg"

const DEFAULT_BG:String = "res://theme/background.webp"
const IMAGE_EXT:PackedStringArray = ["webp", "png", "jpg", "jpeg", "svg"]
const STORY_EXT:String = "dat"

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
	"T":Vector2(0.5, 0),
	"TR":Vector2(1, 0),
	"L":Vector2(0, 0.5),
	"C":Vector2(0.5, 0.5),
	"R":Vector2(1, 0.5),
	"BL":Vector2(0, 1),
	"B":Vector2(0.5, 1),
	"BR":Vector2(1, 1),
}

const HORIZONTAL_ALIGNMENTS:Dictionary = {
	"Left":HORIZONTAL_ALIGNMENT_LEFT,
	"Center":HORIZONTAL_ALIGNMENT_CENTER,
	"Right":HORIZONTAL_ALIGNMENT_RIGHT,
}

var DELAY_TYPES:Array[String] = [
	"Never",
	"ms",
	"Clicks",
]


#Regular expressions
#var _rex_bracketed_expressions:RegEx = RegEx.new()
var _rex_code_tags:RegEx = RegEx.new()
var _rex_tag_params:RegEx = RegEx.new()
var _rex_escape_chars:RegEx = RegEx.new()
var _rex_sanitize_varname:RegEx = RegEx.new()


#NOTE: That these events are emitted by the player saving and loading their game file, and NOT by the author saving a page (that emits editor_save) or by any page being loaded
signal before_saved
signal after_saved
signal before_loaded
signal after_loaded

signal editor_saved
signal editor_renamed
signal editor_deleted

signal started
signal page_changed
signal quitted

var config:ConfigFile = ConfigFile.new()
var book:ComicBook
var vars:Dictionary
var temp:Dictionary = {}

var theme:Theme

var size:Vector2
var image_scale:float = 1

var shapes:Dictionary = {}
var edge_styles:Dictionary = {}
var tail_tips:Dictionary = {}
var tail_styles:Dictionary = {}

# These are ComicScript language constructs, rather than callable commands - we put them in the _commands dictionary to stop people from adding a command of the same name (which would be ignored without error, otherwise)
#var commands:Dictionary = {
	#"*": null, 
	#"+": null, 
	#"set": null,
	#"if": null, "while": null, 
	#"else": null, "elif": null,
#}
#var _replacer_keys_ordered:Array[String] = []
var replacers:Dictionary = {}
var _code_tags:Dictionary = {}
var editor_menu_items:Array = []

var preset_properties:Dictionary = {
	"balloon": {
		"align": HORIZONTAL_ALIGNMENTS,
		"anchor": "vector2",
		"anchor_to": ANCHOR_POINTS,
		"appear": "int",
		"appear_type": DELAY_TYPES,
		"bold": "bool",
		"bold_is_italic": "bool",
		"collapse": "bool",
		"content": "string",
		"disappear": "int",
		"disappear_type": DELAY_TYPES,
		"edge_color": "color",
		"edge_style": "edge_style",
		"edge_thickness": "int",
		"font": "font",
		"font_color": "color",
		"fill_color": "color",
		"fragment": "string",
		"height": "int",
		"image": "image",
		"italic": "bool",
		"layer": LAYERS,
		"nine_slice": "vector4i",
		"padding": "vector4i",
		"scale_all": "percent",
		"scale_box": "percent",
		"scale_edge_h": "percent",
		"scale_edge_w": "percent",
		"scale_font": "percent",
		"scroll": "bool",
		"shape": "shape",
		"shown": "bool",
		"squirk": "percent",
		"tail_width": "int",
		"width": "int",
	},
	"book": {
		"auto_save_slot": "bool",
		"manual_save_slots": "bool",
	},
	"button": {
		"action": ComicButton.Action,
		"action_bookmark": "bookmark",
		"action_commands": "string",
		"appear": "int",
		"appear_type": DELAY_TYPES,
		"content": "string",
		"disappear": "int",
		"disappear_type": DELAY_TYPES,
		"enabled_test": "string",
		"fill_color": "color",
		"fill_color_disabled": "color",
		"fill_color_hovered": "color",
		"font_color": "color",
		"font_color_disabled": "color",
		"font_color_hovered": "color",
		"fragment": "string",
		"shown": "bool",
	},
	"hotspot": {
		"action": ComicButton.Action,
		"action_bookmark": "bookmark",
		"action_commands": "string",
		"anchor": "vector2",
		"appear": "int",
		"appear_type": DELAY_TYPES,
		"change_cursor": "bool",
		"disappear": "int",
		"disappear_type": DELAY_TYPES,
		"fragment": "string",
		"points": "array",
		"shown": "bool",

	},
	"image": {
		"anchor": "vector2",
		"anchor_to": ANCHOR_POINTS,
		"appear": "int",
		"appear_type": DELAY_TYPES,
		"disappear": "int",
		"disappear_type": DELAY_TYPES,
		"file_name": "image",
		"flip": "bool",
		"fragment": "string",
		"layer": LAYERS,
		"rotate": "degrees",
		"shown": "bool",
		"tint": "color",
		"width": "int",
	},
	"kaboom": {
		"align": HORIZONTAL_ALIGNMENTS,
		"anchor": "vector2",
		"bulge": "percent",
		"content": "string",
		"appear": "int",
		"appear_type": DELAY_TYPES,
		"disappear": "int",
		"disappear_type": DELAY_TYPES,
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
		"shown": "bool",
		"spacing": "percent",
		"wave_period": "percent",
		"wave_height": "percent",
	},
	"line": {
		"anchor": "vector2",
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
	"page": {
		"action": "int",
		"action_bookmark": "string",
		"action_commands": "string",
		"allow_back": "bool",
		"allow_save": "bool",
		"auto_save": "bool",
		"bg_color": "color",
	}
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
			"shown": true,
			"squirk": 0.5,
			"tail_width": 8,
			"width": 288,
		},
		"caption": {
			"align": HORIZONTAL_ALIGNMENT_LEFT,
			"anchor_to": Vector2.ZERO,
			"fill_color": Color(1,1,0.6),
			"italic": true,
			"padding": Vector4i(16,4,16,4),
			"shape": "box",
		},
		"thought": {
			"edge_style": "cloud",
			"italic": true,
		},
		"whisper": {
			"edge_style": "dash",
			"italic": true,
			"scale_box": 0.75,
		},
		"yell": {
			"edge_style": "burst",
			"bold": true,
		},
	},
	"book": {
		"": {
			"auto_save_slot": true,
			"init_commands": "",
			"manual_save_slots": true,
		}
	},
	"button": {
		"": {
			"action": ComicButton.Action.NEXT,
			"action_bookmark": "",
			"action_commands": "",
			"content": "New Button",
			"enabled_test": "true",
			"fill_color": Color.BLACK,
			"fill_color_disabled": Color(0.2, 0.2, 0.2),
			"fill_color_hovered": Color.BLACK,
			"font_color": Color.WHITE,
			"font_color_disabled": Color(0.6, 0.6, 0.6),
			"font_color_hovered": Color.YELLOW,
			"shown": true,
		},
	},
	"hotspot": {
		"": {
			"action": ComicButton.Action.NEXT,
			"action_bookmark": "",
			"action_commands": "",
			"change_cursor": true,
			"shown": true,
		}
	},
	"image": {
		"": {
			"shown": true,
			"tint": Color.WHITE,
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
			"shown": true,
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
	"page": {
		"": {
			"action": ComicButton.Action.NEXT,
			"action_bookmark": "",
			"action_commands": "",
			"allow_back": true,
			"allow_save": true,
			"auto_save": false,
		}
	}
}
var get_preset_options:Dictionary = {
	"shape": get_preset_options_shape,
	"edge_style": get_preset_options_edge_style,
	"image": get_images_file_names,
}

# ------------------------------------------------------------------------------
# Getters and setters

var full_screen:bool:
	get:
		return config.get_value("viewer", "full_screen", true)
	set(value):
		config.set_value("viewer", "full_screen", value)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED)

# ------------------------------------------------------------------------------


func _init():
	config.load(CONFIG_FILE)
	print(config.get_sections())
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if full_screen else DisplayServer.WINDOW_MODE_WINDOWED)
	theme = preload("res://theme/default.tres")
	size = Vector2(float(ProjectSettings["display/window/size/viewport_width"]), float(ProjectSettings["display/window/size/viewport_height"]))
	#_units_in_width = theme.get_constant("units_in_width", "Settings")
	#px_per_unit = float(size.x) / _units_in_width
	#_image_px_per_unit = theme.get_constant("image_px_per_unit", "Settings")
	
	#Set up regular expressions
	recompile_rex_code_tags()
	# This regex, which is used for separating a tag's parameters, needs testing and, if possible, optimisation. (But it's broken my brain enough for now.) 
	#NOTE: It also doesn't allow for nested quotes of the same type, and has no way to escape them, which isn't ideal but I'm okay with it.
	_rex_tag_params.compile("[A-Za-z_]\\w*(\\s*=\\s*(([^\\\"\\']|\\\"[^\\\"]*\\\"|\\'[^\\']*\\')*?((?<=[\\\"\\'])|[^+\\-*\\/=\\(\\[\\{])(?=\\s+[A-Za-z_]|$)))?")
	_rex_escape_chars.compile("[\\\\\\.\\^\\$\\*\\+\\?\\(\\)\\[\\]\\{\\}\\|]")
	_rex_sanitize_varname.compile("[^a-zA-Z0-9_\\ ]")

	#for ext in IMAGE_EXT:
		#var path: String = str("res://theme/background.", ext)
		#if ResourceLoader.exists(path):
			#default_bg_path = path
			#var bg_texture:Texture2D = load(path)
			#image_scale = size.x / bg_texture.get_width()
			#var image_scale_h = size.y / bg_texture.get_height()
			#assert(image_scale == image_scale_h, "The background image must be the same ratio as the viewport width set in the project settings")
			#break

func _ready():
	#We want to manually handle quit requests via the quit() method, which does things like save the config file.
	get_tree().set_auto_accept_quit(false)

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

	add_shape(ComicImageShape.new(), ComicImageEdgeStyle.new())

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

	add_code_tag("store", _code_tag_store, true)
	add_code_tag("if", _code_tag_if, true, "else")
	add_code_tag("save", _code_tag_save)
	add_code_tag("load", _code_tag_load)
	add_code_tag("save_exists", _code_tag_save_exists)
	add_code_tag("go", _code_tag_go, true)
	add_code_tag("visit", _code_tag_visit, true)
	add_code_tag("back", _code_tag_back)
	add_code_tag("next", _code_tag_next)
	add_code_tag("return", _code_tag_return)
	add_code_tag("menu", _code_tag_menu)
	add_code_tag("wait", _code_tag_wait, true)

	add_editor_menu_item(0, "Page/Chapter Properties", str(ComicEditor.DIR_ICONS, "properties.svg"), ComicEditor.menu_open_page_properties)
	add_editor_menu_item(0, "Book Properties", str(ComicEditor.DIR_ICONS, "properties.svg"), ComicEditor.menu_open_book_properties)
	add_editor_menu_item(0, "Editor Properties", str(ComicEditor.DIR_ICONS, "properties.svg"), ComicEditor.menu_open_settings_properties)
	add_editor_submenu(0, "Fragment Properties", "fragment", ComicEditor.build_submenu_fragment_properties, ComicEditor.submenu_fragment_index_pressed)

	add_editor_menu_item(1, "Add Balloon", str(ComicEditor.DIR_ICONS, "shape_balloon.svg"), ComicEditor.menu_add_balloon)
	add_editor_menu_item(1, "Add Caption", str(ComicEditor.DIR_ICONS, "shape_box.svg"), ComicEditor.menu_add_caption)
	add_editor_menu_item(1, "Add Kaboom", str(ComicEditor.DIR_ICONS, "kaboom.svg"), ComicEditor.menu_add_kaboom)

	add_editor_menu_item(2, "Add Button", str(ComicEditor.DIR_ICONS, "button.svg"), ComicEditor.menu_add_button)
	add_editor_menu_item(2, "Add Hotspot", str(ComicEditor.DIR_ICONS, "hotspot.svg"), ComicEditor.menu_add_hotspot)

	add_editor_menu_item(3, "Change Background", str(ComicEditor.DIR_ICONS, "background.svg"), ComicEditor.menu_change_background)
	add_editor_submenu(3, "Add Image", "image", ComicEditor.build_submenu_add_image, ComicEditor.submenu_image_index_pressed)
	add_editor_menu_item(3, "Add Border Line", str(ComicEditor.DIR_ICONS, "frame_border.svg"), ComicEditor.menu_add_line)

	add_editor_menu_item(4, "Add Note", str(ComicEditor.DIR_ICONS, "note.svg"), ComicEditor.menu_add_note)

	add_editor_menu_item(5, str("Undo (", ComicEditor.command_or_control , "+Z)"), str(ComicEditor.DIR_ICONS, "undo.svg"), ComicEditor.menu_undo)
	add_editor_menu_item(5, str("Redo (", ComicEditor.command_or_control , "+Y)"), str(ComicEditor.DIR_ICONS, "redo.svg"), ComicEditor.menu_redo)

	add_editor_menu_item(6, str("Save (", ComicEditor.command_or_control , "+S)"), str(ComicEditor.DIR_ICONS, "save.svg"), ComicEditor.menu_save)
	add_editor_menu_item(6, str("Save and Quit (", ComicEditor.command_or_control , "+Shift+S)"), str(ComicEditor.DIR_ICONS, "save.svg"), ComicEditor.menu_save_and_quit)
	add_editor_menu_item(6, str("Quit Without Saving (", ComicEditor.command_or_control , "+Q)"), str(ComicEditor.DIR_ICONS, "delete.svg"), ComicEditor.menu_quit)

	replacers["[b]"] = "[b][i]"
	replacers["[/b]"] = "[/i][/b]"
	#TODO: Make some of these font features instead? Or allow them to be somehow toggled off for other fonts?
	var rex_capital_i_in_word:RegEx = RegEx.new()
	rex_capital_i_in_word.compile("I(?=\\w)|(?<=\\w)I")
	replacers[rex_capital_i_in_word] = "i"
	replacers["[I]"] = "I" # To allow author to force a capital I in a word.
	replacers["[br]"] = "\n"
	replacers["[tab]"] = "	"
	replacers["[tilde]"] = "~"
	replacers["[at]"] = "@"
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

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()

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

func add_editor_menu_item(section_pos:int, text:String, icon_path:String, callable:Callable):
	while editor_menu_items.size() < section_pos + 1:
		editor_menu_items.push_back([])
	editor_menu_items[section_pos].push_back({"text":text, "icon_path":icon_path, "callable":callable})

func add_editor_submenu(section_pos:int, text:String, submenu_id:String, submenu_build:Callable, submenu_click:Callable):
	while editor_menu_items.size() < section_pos + 1:
		editor_menu_items.push_back([])
	editor_menu_items[section_pos].push_back({"text":text, "submenu_id":submenu_id, "submenu_build":submenu_build, "submenu_click":submenu_click})


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

func execute(command: String) -> Variant:
	#if Comic.book is ComicEditor:
		## We don't execute code in the editor - we display it.
		#return str("[bgcolor=#ccc]", command, "[/bgcolor]")

	#print("Executing ", command, " as ", command.replace("~", "vars.").replace("@", "temp."))
	var expression = Expression.new()
#	var error = expression.parse(command.replace("~", "vars.").replace("@", "temp."), ["vars", "temp"])
	var error = expression.parse(command.replace("~", "vars.").replace("@", "temp."))
	if error != OK:
		print(expression.get_error_text())
		push_error(expression.get_error_text())
		return "<<Error>>"
#	var result = expression.execute([vars, temp], self)
	var result = expression.execute([], self)
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
	#print("Executing embedded code: ", s)
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
			#print("No matches left")
			r = str(r, s.substr(offset))
			finished = true
		else:
			#Add all content before the match to the return string
			r = str(r, s.substr(offset, rex_match.get_start() - offset))
			if rex_match.strings[1][0] == "[":
				# This is double-bracketed raw code. index 1 is the match with one set of brackets - we need to strip them off and execute the contents
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
				
				if _code_tags[key].has("rex_closing_tags"):
					var nest_level:int = 0
					var contents:Array = []
					for closing_match in _code_tags[key].rex_closing_tags.search_all(s, offset):
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
		if pair.size() == 1:
			r[pair[0].strip_edges()] = null
		else:
			r[pair[0].strip_edges()] = pair[1].strip_edges()
	return r

func parse_hidden_string(s:String):
	if OS.is_debug_build():
		print(execute_embedded_code(s))
	else:
		execute_embedded_code(s)

func parse_rich_text_string(s: String) -> String:
	# In the editor we'll have un-executed code that we want to style.
	for key in replacers:
		if key is RegEx:
			# Regex replacement
			s = key.sub(s, replacers[key], true)
		else:
			# String replacement
			s = s.replace(key, replacers[key])
	if s == "":
		s = " " # This is to ensure that empty speech balloons in the editor don't disappear entirely
	return s

func parse_bool_string(s: String) -> bool:
	s = s.strip_edges().to_lower()
	return s == "true" or s == "yes" or s == "1"

func split_tag_params(s:String) -> Dictionary:
	var r:Dictionary = {}
	for match in _rex_tag_params.search_all(s):
		r[match.strings[1]] = match.strings[2]
	return r

func validate_name(s:String) -> String:
	s = s.replace("-", "_")
	s = _rex_sanitize_varname.sub(s, "", true).to_lower().to_snake_case()
	s = s.lstrip("_").rstrip("_")
	return s
	
func request_quit():
	if book.has_unsaved_changes:
		confirm("Really quit?", str("Any unsaved ", "changes" if book is ComicEditor else "progress", " will be lost.\n\nAre you sure you want to quit?"), quit)
	else:
		quit()

func quit():
	config.save(CONFIG_FILE)
	quitted.emit()
	get_tree().quit()

func get_seed_from_position(v:Vector2) -> int:
	return int(v.x + v.y * size.x)

func alert(title:String, text:String, callback:Callable = Callable()):
	confirm(title, text, callback, "OK", "")

func confirm(title:String, text:String, confirm_callback:Callable = Callable(), confirm_text:String = "Yes", cancel_text:String = "No", cancel_callback:Variant = null):
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = text
	dialog.ok_button_text = confirm_text
	dialog.confirmed.connect(dialog.queue_free)
	dialog.confirmed.connect(confirm_callback)
	if cancel_text != "":
		dialog.add_cancel_button(cancel_text)
		dialog.canceled.connect(dialog.queue_free)
		if cancel_callback != null:
			dialog.canceled.connect(cancel_callback)
	add_child(dialog)
	dialog.popup_centered()

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
			"array":
				return []
			"bookmark":
				return "start"
			"bool":
				return false
			"color":
				return Color.BLACK
			"degrees", "int":
				return 0
			"image":
				return ""
			"font":
				return "default"
			"percent":
				return 1.0
			"string":
				return ""
			"vector2":
				return Vector2.ZERO
			"vector2i":
				return Vector2i.ZERO
			"vector3":
				return Vector3.ZERO
			"vector3i":
				return Vector3i.ZERO
			"vector4":
				return Vector4.ZERO
			"vector4i":
				return Vector4i.ZERO
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

func get_images_file_names() -> Array:
	var a = []
	for file_name in DirAccess.get_files_at(DIR_IMAGES):
		if IMAGE_EXT.has(file_name.get_extension().to_lower()):
			a.push_back(file_name)
	return a

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

func _code_tag_store(params:Dictionary, contents:Array) -> String:
	#print("Storing: ", params)
	if params.has("var"):
		var s = execute_embedded_code(contents[0])
		#print(s)
		
		var o:Variant = null
		if params.has("oid"):
			o = Comic.book.page.os.get(int(params.oid))

		var f:Callable = set_var if o == null else o._data_set
		
		var data_type:String = ""
		if params.has("type"):
			data_type = params["type"].to_lower()
		elif o != null and "otype" in o and preset_properties.has(o.otype):
			# Get the type from the preset properties of the object being altered
			var variant_data_type:Variant = preset_properties[o.otype].get(params.var, "string")
			if variant_data_type is Array:
				data_type = "int"
			elif variant_data_type is Dictionary:
				data_type = "string"
			else:
				data_type = str(variant_data_type)
		match data_type:
			"string":
				f.call(params.var, s)
			"int":
				f.call(params.var, int(s))
			"float":
				f.call(params.var, float(s))
			"bool":
				f.call(params.var, parse_bool_string(s))
			"color":
				var parts = s.split(",")
				match parts.size():
					1:
						# Hex code or standardized color name
						f.call(params.var, Color(s))
					3:
						f.call(params.var, Color(float(s[0]), float(s[1]), float(s[2])))
					4:
						f.call(params.var, Color(float(s[0]), float(s[1]), float(s[2]), float(s[3])))
					_:
						f.call(params.var, Color.BLACK)
			"vector2":
				var parts = s.split(",")
				if parts.size() == 2:
					f.call(params.var, Vector2(float(s[0]), float(s[1])))
				else:
					f.call(params.var, Vector2.ZERO)
			"vector3":
				var parts = s.split(",")
				if parts.size() == 3:
					f.call(params.var, Vector3(float(s[0]), float(s[1]), float(s[2])))
				else:
					f.call(params.var, Vector3.ZERO)
			"vector4":
				var parts = s.split(",")
				if parts.size() == 2:
					f.call(params.var, Vector4(float(s[0]), float(s[1]), float(s[2]), float(s[3])))
				else:
					f.call(params.var, Vector4.ZERO)
			"vector2i":
				var parts = s.split(",")
				if parts.size() == 2:
					f.call(params.var, Vector2i(int(s[0]), int(s[1])))
				else:
					set_var(params.var, Vector2i.ZERO)
			"vector3i":
				var parts = s.split(",")
				if parts.size() == 3:
					f.call(params.var, Vector3i(int(s[0]), int(s[1]), int(s[2])))
				else:
					f.call(params.var, Vector3i.ZERO)
			"vector4i":
				var parts = s.split(",")
				if parts.size() == 2:
					f.call(params.var, Vector4i(int(s[0]), int(s[1]), int(s[2]), int(s[3])))
				else:
					f.call(params.var, Vector4i.ZERO)
			_: # Default to code, which gets executed
				f.call(params.var, execute(s))
		if o != null:
			# After changing the value of an object, we need to rebuild the page.
			if params.var == "shown":
				# Unless we're just changing visibility, in which case we can get away with just changing the visibility of this object and redrawing the page.
				if o.shown:
					o.show()
				else:
					o.hide()
				book.page.redraw(false)
			else:
				book.page.rebuild(true)

	else:
		return "<store error - no var given>"
	return ""


func _code_tag_if(params:Dictionary, contents:Array) -> String:
	if execute(params[""]):
		return contents[0]
	elif contents.size() > 1:
		return contents[1]
	return ""

func _code_tag_go(_params:Dictionary, contents:Array) -> String:
	book.page_go(execute_embedded_code(contents[0]))
	return ""

func _code_tag_visit(_params:Dictionary, contents:Array) -> String:
	book.page_visit(execute_embedded_code(contents[0]))
	return ""

func _code_tag_back(_params:Dictionary) -> String:
	book.page_back()
	return ""

func _code_tag_next(_params:Dictionary) -> String:
	book.page_next()
	return ""

func _code_tag_return(_params:Dictionary) -> String:
	book.page_return()
	return ""

func _code_tag_quit(params:Dictionary) -> String:
	# By default we confirm that the player wants to quit
	if not params.has("ask") or not parse_bool_string(params.ask):
		quit()
	else:
		request_quit()
	return ""


func _code_tag_save(params:Dictionary) -> String:
	if params.has("slot"):
		save_savefile(int(params.slot))
	else:
		# No slot given - open the save menu.
		ComicSavesMenu.open(true)
	return ""

func _code_tag_load(params:Dictionary) -> String:
	if params.has("slot"):
		load_savefile(int(params.slot))
	elif book.manual_save_slots:
		# No slot given - open the load menu.
		ComicSavesMenu.open(false)
	elif book.auto_save_slot:
		# No slot given but we only have the autosave slot, so load it.
		load_savefile(0)
	return ""

func _code_tag_save_exists(params:Dictionary) -> String:
	var slot:int = -1
	if params.has("slot"):
		slot = int(params.slot)
	if save_exists(slot):
		return "true"
	else:
		return "false"

func _code_tag_menu(_params:Dictionary) -> String:
	ComicMenu.open()
	return ""

func _code_tag_wait(params:Dictionary, contents:Array) -> String:
	if params.has("clicks"):
		var click_counter:Dictionary = {
			"clicks": int(params.clicks),
			"s": contents[0],
		}
		if params.has("persist"):
			click_counter.persist = null
		Comic.book.click_counters.push_back(click_counter)
	else:
		var timer:Dictionary = {
			"t": 1,
			"s": contents[0],
		}
		if params.has("t"):
			timer.t = float(params.t)
		if params.has("persist"):
			timer.persist = null
		Comic.book.timers.push_back(timer)
	return ""

func save_savefile(save_id:int):
	before_saved.emit()
	book.has_unsaved_changes = false
	var file = FileAccess.open(str(DIR_SAVES, "data_", save_id, ".sav"), FileAccess.WRITE)
	file.store_var(Comic.vars)
	var capture = Comic.book.page.get_texture().get_image()
	capture.resize(ProjectSettings.get_setting("display/window/size/viewport_width") / 4, ProjectSettings.get_setting("display/window/size/viewport_height") / 4)
	capture.save_webp(str(DIR_SAVES, "thumb_", save_id, ".webp"))
	after_saved.emit()


func load_savefile(save_id:int):
	var path = str(Comic.DIR_SAVES, "data_", save_id, ".sav")
	if FileAccess.file_exists(path):
		before_loaded.emit()
		var file = FileAccess.open(path, FileAccess.READ)
		Comic.vars = file.get_var()
		Comic.book.change_page = true
		after_loaded.emit()

func save_exists(slot:int = -1) -> bool:
	if slot > -1:
		return FileAccess.file_exists(str(Comic.DIR_SAVES, "data_", slot, ".sav"))
	elif Comic.book.auto_save_slot or Comic.book.manual_save_slots:
		# No slot specified - check if ANY saves exist
		for i in 9 if Comic.book.manual_save_slots else 1:
			if FileAccess.file_exists(str(Comic.DIR_SAVES, "data_", i, ".sav")):
				return true
	return false

func set_var(key:String, value:Variant):
	if key[0] == "~":
		# Remove optional tilde
		key = key.substr(1)
		vars[key] = value
	elif key[0] == "@":
		# Store in temp variables instead of vars
		# Remove at sign
		key = key.substr(1)
		temp[key] = value
	else:
		# No preceding character - assume it's meant to go in vars.
		vars[key] = value

func get_var(key:String) -> Variant:
	if key[0] == "~":
		# Remove optional tilde
		key = key.substr(1)
		return vars.get(key)
	elif key[0] == "@":
		# Store in temp variables instead of vars
		# Remove at sign
		key = key.substr(1)
		return temp.get(key)
	else:
		# No preceding character - assume it's meant to go in vars.
		return vars.get(key)
