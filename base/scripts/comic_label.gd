class_name ComicLabel
extends Control

const DEFAULT_TEXT:String = "POW!"
const BASE_FONT_SIZE:int = 32
const FOREGROUND_CHARS = "~!@#$%^&*()_+`-={}|[]\\:;'\"''“”<>?,./"

var data:Dictionary
var default_data:Dictionary

var width:float

# ------------------------------------------------------------------------------

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

var bulge:float:
	get:
		return _data_get("bulge")
	set(value):
		_data_set("bulge", value)

var curve_period:float:
	get:
		return _data_get("curve_period")
	set(value):
		_data_set("curve_period", value)

var curve_height:float:
	get:
		return _data_get("curve_height")
	set(value):
		_data_set("curve_height", value)

var font:Font:
	get:
		return load(str(Comic.DIR_FONTS, "label/", _data_get("font_name")))
	set(value):
		_data_set("font_name", value.get_font_name())

var font_color:Color:
	get:
		return _data_get("font_color")
	set(value):
		_data_set("font_color", value)

var font_size:float:
	get:
		return _data_get("font_size")
	set(value):
		_data_set("font_size", value)

var grow:float:
	get:
		return _data_get("grow")
	set(value):
		_data_set("grow", value)

var layer:int:
	get:
		return _data_get("layer")
	set(value):
		_data_set("layer", value)

var oid:int:
	get:
		return data.oid
	set(value):
		data.oid = value

var outline_color:Color:
	get:
		return _data_get("outline_color")
	set(value):
		_data_set("outline_color", value)

var outline_thickness:float:
	get:
		return _data_get("outline_thickness")
	set(value):
		_data_set("outline_thickness", value)

var presets:Array:
	get:
		if not data.has("presets"):
			data.presets = []
		return data.presets
	set(value):
		data.presets = value

var r:float:
	get:
		return _data_get("r")
	set(value):
		_data_set("r", value)

var rotate_chars:bool:
	get:
		return _data_get("rotate_chars")
	set(value):
		_data_set("rotate_chars", value)

var spacing:float:
	get:
		return _data_get("spacing")
	set(value):
		_data_set("spacing", value)

var rng_seed:int:
	get:
		return data.rng_seed
	set(value):
		data.rng_seed = value

# ------------------------------------------------------------------------------

func _init(_data:Dictionary, page:ComicPage):
	print("INIT LABEL")
	data = _data
	default_data = _get_default_data()
	if not data.has("oid"):
		data.oid = Comic.book.page.make_oid()
	page.os[oid] = self
	if not data.has("anchor"):
		data.anchor = Vector2.ZERO
	if not data.has("rng_seed"):
		data.rng_seed = Comic.get_seed_from_position(data.anchor)
	if not data.has("text"):
		data.text = DEFAULT_TEXT

func apply_data():
	default_data = _get_default_data()

	var parent_layer = Comic.book.page.get_layer(layer)
	if get_parent() != parent_layer:
		if get_parent() != null:
			get_parent().remove_child(self)
		parent_layer.add_child(self)

	#Set some basic values of the RichTextLabel
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	
	var rng = RandomNumberGenerator.new()
	rng.seed = rng_seed

	var s = Comic.parse_rich_text_string(data.text)

	for child in get_children():
		remove_child(child)
		child.queue_free()

	var text_server:TextServer = TextServerManager.get_primary_interface()
	# First, we calculate the t values for each char - the position of their center from the position of the first char's center to the last char's center
	var font_rid:RID = font.get_rids()[0]
	var char_font_size:Array[float] = []
	var char_str:Array = []
	var char_int:Array = []
	var glyph:Array = []
	var char_size:Array = []
	var pos:Array = []
	var t:Array = []
	var rot = []

	# Calculate everything based on the initial font size
	for i in s.length():
		char_font_size.push_back(font_size)
		char_str.push_back(s.substr(i,1))
		char_int.push_back(s.unicode_at(i))
		glyph.push_back(text_server.font_get_glyph_index(font_rid, int(char_font_size[i]), char_int[i], 0))
		char_size.push_back(font.get_char_size(char_int[i], int(char_font_size[i])))
		if i == 0:
			pos.push_back(Vector2.ZERO)
		else:
			pos.push_back(pos[i - 1] + Vector2((char_size[i - 1].x + char_size[i].x) / 2.0, 0))
		rot.push_back(0)
	# t is pos, but in the range 0 to 1
	for i in pos.size():
		t.push_back(pos[i].x / pos[-1].x)
	
	# Apply scaling effects
	# Grow
	if grow != 1 or bulge != 1:
		# Calculate variable font size at each index, based on t.
		# Then recalculate char_size, pos, and fiunally t, based on variable font sizes.
		for i in char_font_size.size():
			if grow != 1:
				char_font_size[i] *= 1 + (grow - 1) * pow(t[i], 2.0 if grow > 1 else 0.5)
			if bulge != 1:
				char_font_size[i] *= 1 + (bulge - 1) * sin(t[i] * PI)
			char_size[i] = font.get_char_size(char_int[i], int(char_font_size[i])) if char_font_size[i] > 0 else Vector2.ZERO
			if i == 0:
				pos[i] = Vector2.ZERO
			else:
				pos[i] = pos[i - 1] + Vector2((char_size[i - 1].x + char_size[i].x) / 2.0, 0)
		for i in pos.size():
			t[i] = pos[i].x / pos[-1].x
			
	#Apply spacing
	if spacing != 1:
		for i in pos.size():
			pos[i].x *= spacing

	# We grab the size after scaling but before applying the curve or any random jitter to the position
	width = pos[-1].x

	# Apply curve effects
	if curve_height != 0:
		for i in pos.size():
			pos[i] += Vector2.UP * (sin(TAU * t[i] / curve_period) * curve_height * pos[-1].x)
			if rotate_chars:
				# Full disclosure: There was a lot of trial and error here, but it SEEMS to be right?
				rot[i] += Vector2(curve_period / TAU, -cos(TAU * t[i] / curve_period) * curve_height).angle()
				
	# Apply character effects


	#Apply rotation
	rotation = r

	#Apply alignment
	match align:
		HORIZONTAL_ALIGNMENT_LEFT:
			pivot_offset = Vector2.ZERO
		HORIZONTAL_ALIGNMENT_CENTER:
			pivot_offset = Vector2(width / 2, 0)
		HORIZONTAL_ALIGNMENT_RIGHT:
			pivot_offset = Vector2(width, 0)
	position = anchor - pivot_offset

	var char_obj:Array[ComicChar] = []
	for i in char_str.size():
		char_obj.push_back(ComicChar.new(char_str[i], font, int(char_font_size[i]), font_color, outline_color, int(outline_thickness), pos[i], char_size[i], rot[i]))
		add_child(char_obj[i])
		if i > 0 and not FOREGROUND_CHARS.contains(char_str[i]):
			# Move normal characters behind existing ones, but don't do this for punctuation.
			# Unfortunately, there's no way to add a node before the first node, so this two-step process is needed.
			move_child(char_obj[i], 0)
		char_obj[i].name = char_str[i]

	name = str("Label (", oid, ")")

func rebuild(_rebuild_sub_objects:bool = false):
	apply_data()

# ------------------------------------------------------------------------------

func is_default(key:Variant):
	return _data_get(key) == default_data[key]

func _data_get(key:Variant):
	return data.get(key, default_data[key])

func _data_set(key:Variant, value:Variant):
	if value == default_data[key]:
		data.erase(key)
	else:
		data[key] = value

func _get_default_data() -> Dictionary:
	var ret = {
		"align": HORIZONTAL_ALIGNMENT_CENTER,
		"anchor": Vector2.ZERO,
		"bulge": 1.0,
		"curve_period": 2.0,
		"curve_height": 0.0,
		"font_name": Comic.theme.get_font("font", "Label").get_path().get_file(),
		"font_size": Comic.theme.get_font_size("font_size", "Label"),
		"font_color": Comic.theme.get_color("font_color", "Label"),
		"grow": 1.0,
		"layer": Comic.theme.get_constant("layer", "Label"), # We put labels on the top layer by default
		"outline_color": Comic.theme.get_color("font_outline_color", "Label"),
		"outline_thickness": Comic.theme.get_constant("outline_size", "Label"),
		"r": 0,
		"rotate_chars": true,
		"spacing": 1.0,
	}

	# We iterate over the full list of presets, rather than the array, because we want to apply presets in the order they appear in that list
	for preset_key in Comic.label_presets.keys():
		if presets.has(preset_key):
			# We have this preset - apply all its keys to the default data 
			for key in Comic.label_presets[preset_key].keys():
				ret[key] = Comic.label_presets[preset_key][key]

	return ret
