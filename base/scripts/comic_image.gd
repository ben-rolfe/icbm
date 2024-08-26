class_name ComicImage
extends TextureRect

var center_point:Vector2
var _data:Dictionary
var _default_data:Dictionary

# ------------------------------------------------------------------------------

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
			
var file_name:String:
	get:
		return _data_get("file_name")
	set(value):
		_data_set("file_name", value)

var flip:bool:
	get:
		return _data_get("flip")
	set(value):
		_data_set("flip", value)

var fragment:String:
	get:
		return _data_get("fragment")
	set(value):
		_data_set("fragment", value)

var layer:int:
	get:
		return _data_get("layer")
	set(value):
		_data_set("layer", value)

var oid:int:
	get:
		return _data.oid
	set(value):
		_data.oid = value

var presets:Array:
	get:
		if not _data.has("presets"):
			_data.presets = []
		return _data.presets
	set(value):
		_data.presets = value

var rotate:float:
	get:
		return _data_get("rotate")
	set(value):
		_data_set("rotate", value)

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
			Comic.book.page.redraw()

var tint:Color:
	get:
		return _data_get("tint")
	set(value):
		_data_set("tint", value)

var width:int:
	get:
		return _data_get("width")
	set(value):
		_data_set("width", value)
		recalc_size()


# ------------------------------------------------------------------------------

func _init(data:Dictionary, page:ComicPage):
	_data = data
	_default_data = Comic.get_preset_data("image", presets)
	if not _data.has("otype"):
		_data.otype = "image"
	if not _data.has("oid"):
		oid = page.make_oid()
	page.os[oid] = self
	name = str("Image (", oid, ")")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	if not self is ComicEditorImage:
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

func apply_data():
	# First, we recreate the _default_data dictionary, because it is affected by selected presets, which may have changed
	_default_data = Comic.get_preset_data("image", presets)
	
	var parent_layer = Comic.book.page.layers[layer]
	if get_parent() != parent_layer:
		if get_parent() != null:
			get_parent().remove_child(self)
		parent_layer.add_child(self)

	# Setting null seems necessary to change the bg after updating the file.
	texture = null
	if _data.has("new_path"):
		# Using an image that isn't in the resources, yet - load it from the filesystem 
		texture = ImageTexture.create_from_image(Image.load_from_file(_data.new_path))
	else:
		var final_file_name:String = str(Comic.DIR_IMAGES, file_name if Comic.book is ComicEditor else Comic.execute_embedded_code(file_name))
		#NOTE: We don't use Comic.load_texture to load from the library, because file_name includes the extension
		if ResourceLoader.exists(final_file_name):
			texture = ResourceLoader.load(final_file_name)
		elif Comic.book is ComicEditor:
			# We can't find the image - Use a placeholder.
			# This isn't necessarily an error - the problem may be because it includes code, but we're in the editor, so we can't check that.
			texture = ResourceLoader.load("res://addons/icbm_editor/theme/broken_image_placeholder.svg")

	if texture == null:
		# No image - use a transparent image.
		texture = ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
	recalc_size()
	
	pivot_offset = anchor_to * size
	rotation = rotate
	flip_h = flip
	modulate = tint
	
	if shown:
		show()
	else:
		hide()

	
func recalc_size():
	var image_scale:float = float(width) / texture.get_width()
	if image_scale <= 0:
		image_scale = 1
	size = texture.get_size() * image_scale
	position = anchor - anchor_to * size

func rebuild(_rebuild_sub_objects:bool = false):
	apply_data()

# ------------------------------------------------------------------------------

func is_default(key:Variant) -> bool:
	return _data_get(key) == _default_data[key]

func clear_data(key:Variant):
	_data.erase(key)

func _data_get(key:Variant) -> Variant:
	return _data.get(key, _default_data[key])

func _data_set(key:Variant, value:Variant):
	if value == _default_data[key]:
		_data.erase(key)
	else:
		_data[key] = value
