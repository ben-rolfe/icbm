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

var file_name:String:
	get:
		return _data_get("file_name")
	set(value):
		_data_set("file_name", value)

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

var width:int:
	get:
		return _data_get("width")
	set(value):
		_data_set("width", value)

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
		#NOTE: We don't use Comic.load_texture to load from the library, because file_name includes the extension
		texture = ResourceLoader.load(str(Comic.DIR_IMAGES, file_name))
	if texture == null:
		# No background - use black background instead.
		texture = ImageTexture.create_from_image(Image.create(int(Comic.size.x), int(Comic.size.y), false, Image.FORMAT_RGB8))
	var scale:float = width / texture.get_width()
	size = texture.get_size() * scale
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
