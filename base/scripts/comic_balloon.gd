class_name ComicBalloon
extends RichTextLabel

var _final_scale_box:float
var _final_scale_font:float
var _final_scale_edge:Vector2
var _final_collapse:float
var center_point:Vector2
var data:Dictionary
var _default_data:Dictionary
var edge_offsets:PackedVector2Array
var edge_offset_angles:PackedFloat32Array
var edge_points:PackedVector2Array
var edge_segment_length:float
var frame_half_size:Vector2
#var _margins:Vector4
var rng:RandomNumberGenerator
var tails:Dictionary = {}
var tail_backlinks:Array = []

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

var anchor_to:Vector2:
	get:
		return _data_get("anchor_to")
	set(value):
		_data_set("anchor_to", value)

var bold:bool:
	get:
		return _data_get("bold")
	set(value):
		_data_set("bold", value)

var bold_is_italic:bool:
	get:
		return _data_get("bold_is_italic")
	set(value):
		_data_set("bold_is_italic", value)

var collapse:bool:
	get:
		return _data_get("collapse")
	set(value):
		_data_set("collapse", value)

var content:String:
	get:
		return _data_get("content")
	set(value):
		_data_set("content", value)

var edge_color:Color:
	get:
		return _data_get("edge_color")
	set(value):
		_data_set("edge_color", value)

var edge_style:ComicEdgeStyle:
	get:
		return Comic.get_edge_style(_data_get("shape"), _data_get("edge_style"))
	set(value):
		_data_set("shape", value.shape_id)
		_data_set("edge_style", value.id)

var edge_thickness:float:
	get:
		return _data_get("edge_thickness")
	set(value):
		_data_set("edge_thickness", value)

var fill_color:Color:
	get:
		return _data_get("fill_color")
	set(value):
		_data_set("fill_color", value)

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

var height:int:
	get:
		return _data_get("height")
	set(value):
		_data_set("height", value)

var italic:bool:
	get:
		return _data_get("italic")
	set(value):
		_data_set("italic", value)

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

var presets:Array:
	get:
		if not data.has("presets"):
			data.presets = []
		return data.presets
	set(value):
		data.presets = value

var scale_all:float:
	get:
		return _data_get("scale_all")
	set(value):
		_data_set("scale_all", value)

var scale_box:float:
	get:
		return _data_get("scale_box")
	set(value):
		_data_set("scale_box", value)

var scale_edge_h:float:
	get:
		return _data_get("scale_edge_h")
	set(value):
		_data_set("scale_edge_h", value)

var scale_edge_w:float:
	get:
		return _data_get("scale_edge_w")
	set(value):
		_data_set("scale_edge_w", value)

var scale_font:float:
	get:
		return _data_get("scale_font")
	set(value):
		_data_set("scale_font", value)

var scroll:bool:
	get:
		return _data_get("scroll")
	set(value):
		_data_set("scroll", value)

var shape:ComicShape:
	get:
		return Comic.get_shape(_data_get("shape"))
	set(value):
		_data_set("shape", value.id)

var rng_seed:int:
	get:
		return data.rng_seed
	set(value):
		data.rng_seed = value

var squirk:float:
	get:
		return _data_get("squirk")
	set(value):
		_data_set("squirk", value)

var width:int:
	get:
		return _data_get("width")
	set(value):
		_data_set("width", value)

# ------------------------------------------------------------------------------

func _init(_data:Dictionary, page:ComicPage):
	data = _data
	_default_data = Comic.get_preset_data("balloon", presets)
	bbcode_enabled = true
	if not data.has("otype"):
		data.otype = "balloon"
	if not data.has("oid"):
		oid = page.make_oid()
	page.os[oid] = self
	if not data.has("rng_seed"):
		data.rng_seed = Comic.get_seed_from_position(data.anchor)
	if not data.has("tails"):
		data.tails = {}
	
	if not Comic.book is ComicEditor:
		data.text = Comic.execute_embedded_code(data.text)

	name = str("Balloon (", oid, ")")

func apply_data():
	# First, we recreate the _default_data dictionary, because it is affected by selected presets, which may have changed
	_default_data = Comic.get_preset_data("balloon", presets)
	theme = ResourceLoader.load(str(Comic.DIR_FONTS, "balloon/", font, ".tres"))
	
	var parent_layer = Comic.book.page.layers[layer]
	if get_parent() != parent_layer:
		if get_parent() != null:
			get_parent().remove_child(self)
		parent_layer.add_child(self)

	text = "" # We clear any text before we set this initial size, or else in the editor, when we're redrawing this box, we'll end up with a very tall box due to it calculating wrapping before we set its proper width
	size = Vector2.ZERO

	# --------------------------------------------------------------------------
	# SHAPE AND EDGE
	# --------------------------------------------------------------------------
	if edge_style.is_randomized:
		rng = RandomNumberGenerator.new()
		rng.seed = rng_seed

	# --------------------------------------------------------------------------
	# SCALE
	# --------------------------------------------------------------------------
	var scale_edge:Vector2 = Vector2(scale_edge_w, scale_edge_h)
	_final_scale_box = scale_box * scale_all
	# We apply the INVERSE of the (non-final) box scale to the edge. The reason for this is that the edge is drawn based on the box size, but we don't want the box scale to affect the edge.
	# For similar reasons, we DON'T apply the scale_all - it's already applied as part of _final_scale_box
	_final_scale_edge = scale_edge / scale_box
	# We scale the font with the box, since we apply the box scale by changing the size, not by adjusting its scale. We do this to maintain crisp fonts, as actually scaling things buggers them up.
	_final_scale_font = scale_font * scale_all * scale_box
	edge_segment_length = Comic.EDGE_SEGMENT_LENGTH * scale_all

	# @collapse
	# Note that we may overwrite this if @height is set and @overflow is scroll.
	# In that case we never collapse, since it might put the scrollbar outside the bubble
	_final_collapse = collapse

	# @font_
	# default color was reading as black, so override was being removed, but it was displaying as white. Just applying the override no matter what, now.
	#if font_color == theme.get_color("default_color", "RichTextLabel"):
		#print("removing")
		#remove_theme_color_override("default_color")
	#else:
		#print("adding")
		#add_theme_color_override("default_color", font_color)
	add_theme_color_override("default_color", font_color)
	
	# --------------------------------------------------------------------------
	# HEIGHT AND WIDTH (before text is set)
	# --------------------------------------------------------------------------
	if height > 0:
		size.y = height
		fit_content = false
		clip_contents = true
		scroll_active = scroll
		if scroll:
			# We never collapse scrolling boxes, because that would put the scrollbar outside the balloon.
			_final_collapse = false
	else:
		fit_content = true
		clip_contents = false
		scroll_active = false

	# @width
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if width > 0:
		size.x = width
	else:
		# The width has been explicitly set to 0, which means we want unlimited width with no wrapping
		autowrap_mode = TextServer.AUTOWRAP_OFF

	if not is_zero_approx(_final_scale_font):
		remove_theme_font_size_override("bold_font_size")
		remove_theme_font_size_override("bold_italics_font_size")
		remove_theme_font_size_override("italics_font_size")
		remove_theme_font_size_override("mono_font_size")
		remove_theme_font_size_override("normal_font_size")
		if not is_equal_approx(_final_scale_font, 1.0):
			add_theme_font_size_override("bold_font_size", roundi(_final_scale_font * get_theme_font_size("bold_font_size", "RichTextLabel")))
			add_theme_font_size_override("bold_italics_font_size", roundi(_final_scale_font * get_theme_font_size("bold_italics_font_size", "RichTextLabel")))
			add_theme_font_size_override("italics_font_size", roundi(_final_scale_font * get_theme_font_size("italics_font_size", "RichTextLabel")))
			add_theme_font_size_override("mono_font_size", roundi(_final_scale_font * get_theme_font_size("mono_font_size", "RichTextLabel")))
			add_theme_font_size_override("normal_font_size", roundi(_final_scale_font * get_theme_font_size("normal_font_size", "RichTextLabel")))

	if Comic.book is ComicEditor:
		mouse_filter = Control.MOUSE_FILTER_STOP
	elif text.contains("[url"):
		mouse_filter = Control.MOUSE_FILTER_PASS
		connect("meta_clicked", _on_meta_clicked);
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	# --------------------------------------------------------------------------
	# TEXT
	# --------------------------------------------------------------------------
	var pre_text:String
	var post_text:String

	match align:
		HORIZONTAL_ALIGNMENT_LEFT:
			pre_text = str(pre_text, "[left]")
			post_text = str("[/left]", post_text)
		HORIZONTAL_ALIGNMENT_RIGHT:
			pre_text = str(pre_text, "[right]")
			post_text = str("[/right]", post_text)
		_:
			pre_text = str(pre_text, "[center]")
			post_text = str("[/center]", post_text)

	# @bold
	if bold:
		pre_text = str(pre_text, "[b]")
		post_text = str("[/b]", post_text)

	# @italic
	if italic or (bold and bold_is_italic):
		pre_text = str(pre_text, "[i]")
		post_text = str("[/i]", post_text)

	text = str(pre_text, Comic.parse_rich_text_string(content), post_text)

	# ----------------------------------------------------------------------------------------------
	# BOX AND FRAME
	# ----------------------------------------------------------------------------------------------
	# A note on terminology:
	# The BOX is the text box - i.e. the RichTextLabel
	# The FRAME is the *content* of that box (or the whole box, if _final_collapse is false), plus *margins*.
	# Note that the anchor point is relative to the frame, not the box. (e.g. TL is the top-left of the frame)

	var content_size = Vector2(float(get_content_width()) if _final_collapse else size.x, get_content_height())
	frame_half_size = content_size / 2.0

	center_point = anchor + shape.center_adjustment - (anchor_to - Vector2.ONE * 0.5) * frame_half_size * 2
	
	# Safety check
	var viewport_rect:Rect2i = get_viewport_rect()
	if not viewport_rect.has_point(center_point):
		# The center of the balloon cannot be placed off the screen. We adjust the data and recalculate the anchor and center points
		if center_point.x < viewport_rect.position.x:
			anchor.x += viewport_rect.position.x - center_point.x
		elif center_point.x > viewport_rect.position.x + viewport_rect.size.x:
			anchor.x += viewport_rect.position.x + viewport_rect.size.x - center_point.x
		if center_point.y < viewport_rect.position.y:
			anchor.y += viewport_rect.position.y - center_point.y
		elif center_point.y > viewport_rect.position.y + viewport_rect.size.y:
			anchor.y += viewport_rect.position.y + viewport_rect.size.y - center_point.y
		center_point = anchor + shape.center_adjustment - (anchor_to - Vector2.ONE * 0.5) * frame_half_size * 2

	# With those calculated, we can place the box.
	position = center_point - frame_half_size

	# Collapse the frame width to the content width
	if _final_collapse and align != HORIZONTAL_ALIGNMENT_LEFT:
		position.x -= (size.x - content_size.x) * (0.5 if align == HORIZONTAL_ALIGNMENT_CENTER else 1.0)

	#The shape may call for some adjustments of the frame
	shape.adjust_frame_half_size(self)

	# We adjust the frame size according to the scale_edge
	frame_half_size *= scale_edge

	# ----------------------------------------------------------------------------------------------
	# EDGE POINTS
	# ----------------------------------------------------------------------------------------------
	# Now that we know the size and placement of the frame, calculate the edge points. We won't actually use these points until draw_edge and draw_fill are called.
	edge_offsets = PackedVector2Array()
	edge_offset_angles = PackedFloat32Array()
	edge_points = PackedVector2Array()

	edge_style.calculate_offsets(self)
	edge_style.calculate_offset_angles(self)
	edge_style.calculate_points(self)
	
func draw_edge(draw_layer:ComicLayer):
	edge_style.draw_edge(self, draw_layer)

	for tail_oid in data.tails:
		# Draw the tail's edge if the tail is not linked, or if the balloon it's linked to is on the same or a higher layer 
		if not data.tails[tail_oid].linked or Comic.book.page.os[data.tails[tail_oid].end_oid].layer >= layer:
			tails[tail_oid].draw_edge(draw_layer)

	for oids in tail_backlinks:
		# If we're backlinked to a tail on a higher layer, draw it's fill on *this* layer
		if Comic.book.page.os[oids.x].layer > layer:
			Comic.book.page.os[oids.x].tails[oids.y].draw_edge(draw_layer)
	
func draw_fill(draw_layer:ComicLayer):
	if edge_points.size() > 0:
		edge_style.draw_fill(self, draw_layer)

	for tail_oid in data.tails:
		# Draw the tail's fill if the tail is not linked, or if the balloon it's linked to is on the same or a lower layer
		if not data.tails[tail_oid].linked or Comic.book.page.os[data.tails[tail_oid].end_oid].layer <= layer:
			tails[tail_oid].draw_fill(draw_layer)

	for oids in tail_backlinks:
		# If we're backlinked to a tail on a lower layer, draw it's fill on *this* layer
		if Comic.book.page.os[oids.x].layer < layer:
			Comic.book.page.os[oids.x].tails[oids.y].draw_fill(draw_layer)

func _on_meta_clicked(uri:String):
	OS.shell_open(uri)

func rebuild(rebuild_subobjects:bool = false):
	apply_data()
	if rebuild_subobjects:
		rebuild_tails(true)

func rebuild_tails(include_backlinked:bool = false):
	# First, clear out any tails that don't have data (they've been deleted)
	var to_remove:Array = []
	for tail_oid in tails:
		if not data.tails.has(tail_oid):
			to_remove.push_back(tail_oid)
	for tail_oid in to_remove:
		tails.erase(tail_oid)
	
	# Now rebuild the tails from the data (this will add any tails that are new)
	for tail_oid in data.tails:
		rebuild_tail(tail_oid)
	if include_backlinked:
		for oids in tail_backlinks:
			Comic.book.page.os[oids.x].rebuild_tail(oids.y)

func rebuild_tail(tail_oid:int):
	if data.tails.has(tail_oid): # Ignore any request to rebuild a tail that isn't in the data
		if not tails.has(tail_oid):
			# The tail is in the data but doesn't exist (yet) - add it.
			tails[tail_oid] = ComicTail.new(tail_oid, self)
		tails[tail_oid].apply_data()
		if data.tails[tail_oid].has("end_oid"):
			if not Comic.book.page.os[data.tails[tail_oid].end_oid].tail_backlinks.has(Vector2i(oid, tail_oid)):
				Comic.book.page.os[data.tails[tail_oid].end_oid].tail_backlinks.push_back(Vector2i(oid, tail_oid))

# ------------------------------------------------------------------------------

func is_default(key:Variant):
	return _data_get(key) == _default_data[key]

func _data_get(key:Variant):
	return data.get(key, _default_data[key])

func _data_set(key:Variant, value:Variant):
	if value == _default_data[key]:
		data.erase(key)
	else:
		data[key] = value
