class_name ComicKaboom
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

var wave_period:float:
	get:
		return _data_get("wave_period")
	set(value):
		_data_set("wave_period", value)

var wave_height:float:
	get:
		return _data_get("wave_height")
	set(value):
		_data_set("wave_height", value)

var font:String:
	get:
		return _data_get("font")
	set(value):
		_data_set("font", value)

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

var rotate:float:
	get:
		return _data_get("rotate")
	set(value):
		_data_set("rotate", value)

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
	
	# Get the font and font size from the theme
	var font_theme:Theme = ResourceLoader.load(str(Comic.DIR_FONTS, "kaboom/", font, ".tres"))
	var font_face:Font = font_theme.get_font("font", "Label")
	var base_font_size:float = font_theme.get_font_size("font_size", "Label") * font_size

	var parent_layer = Comic.book.page.layers[layer]
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
	var font_rid:RID = font_face.get_rids()[0]
	var char_font_size:Array[float] = []
	var char_str:Array = []
	var char_int:Array = []
	var glyph:Array = []
	var char_size:Array = []
	var pos:Array = []
	var t:Array = []
	var rot = []

	# Calculate everything based on the base font size
	for i in s.length():
		char_font_size.push_back(base_font_size)
		char_str.push_back(s.substr(i,1))
		char_int.push_back(s.unicode_at(i))
		glyph.push_back(text_server.font_get_glyph_index(font_rid, int(char_font_size[i]), char_int[i], 0))
		char_size.push_back(font_face.get_char_size(char_int[i], int(char_font_size[i])))
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
			char_size[i] = font_face.get_char_size(char_int[i], int(char_font_size[i])) if char_font_size[i] > 0 else Vector2.ZERO
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
	if wave_height != 0:
		for i in pos.size():
			pos[i] += Vector2.UP * (sin(TAU * t[i] / wave_period) * wave_height * pos[-1].x)
			if rotate_chars:
				# Full disclosure: There was a lot of trial and error here, but it SEEMS to be right?
				rot[i] += Vector2(wave_period / TAU, -cos(TAU * t[i] / wave_period) * wave_height).angle()
				
	# Apply character effects


	#Apply rotation
	rotation = rotate

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
		char_obj.push_back(ComicChar.new(char_str[i], font_face, int(char_font_size[i]), font_color, outline_color, int(outline_thickness), pos[i], char_size[i], rot[i]))
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
		"wave_period": 2.0,
		"wave_height": 0.0,
		"font": "default",
		"font_size": 1.0,
		"font_color": Color.YELLOW,
		"grow": 1.0,
		"layer": Comic.LAYERS.size() - 1, # We put labels on the top layer by default
		"outline_color": Color.BLACK,
		"outline_thickness": 8,
		"rotate": 0,
		"rotate_chars": true,
		"spacing": 1.0,
	}

	# We iterate over the full list of presets, rather than the array, because we want to apply presets in the order they appear in that list
	for preset_key in Comic.book.presets.kaboom.keys():
		if presets.has(preset_key):
			# We have this preset - apply all its keys to the default data 
			for key in Comic.book.presets.kaboom[preset_key].keys():
				ret[key] = Comic.book.presets.kaboom[preset_key][key]
	return ret
