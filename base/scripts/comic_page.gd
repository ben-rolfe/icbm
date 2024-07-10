class_name ComicPage
extends SubViewport

var bg_path:String
var background:ComicBackground
var layers:Array[ComicLayer] = []

#var layer_depth:int

#NOTE: Bookmark is not stored in data
var bookmark:String

var last_oid:int = -1
var os = {}
#NOTE: The data object of the page is only the data relating to the page itself, not of the contained objects
var _data:Dictionary
var _default_data:Dictionary

# These variables are for when we want to save or load a slot on _process
# Reasons for doing this, rather than calling Comic.save_savefile or Comic.load_savefile include:
# - We're autosaving on page load, and want to let the page fully render before saving, to get a thumbnail
# - We're saving from a tag, and want the page to be fully resolved before we save.
# - We're loading from a tag, and don't want to load Comic.vars from the file and then have it affected by other processes later in the text/page before the page is loaded. 
# - We want to save the page to a slot and then load from a different slot without risking things getting messy
var save_slot:int = -1
var load_slot:int = -1

var hovered_hotspots:Array = []

#-------------------------------------------------------------------------------

var action:ComicButton.Action:
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

var allow_back:bool:
	get:
		return _data_get("allow_back")
	set(value):
		_data_set("allow_back", value)

var allow_save:bool:
	get:
		return _data_get("allow_save")
	set(value):
		_data_set("allow_save", value)

var auto_save:bool:
	get:
		return _data_get("auto_save")
	set(value):
		_data_set("auto_save", value)

var bg_color:Color:
	get:
		return _data_get("bg_color")
	set(value):
		_data_set("bg_color", value)
		RenderingServer.set_default_clear_color(value)

var fragments:Dictionary:
	get:
		return _data.fragments
	set(value):
		_data.fragments = value
		
#-------------------------------------------------------------------------------

func _init(_bookmark: String):
	# With each new page, we reset the temp variables to empty.
	Comic.temp = {}
	bookmark = _bookmark
	name = bookmark.replace("/","__")

	_default_data = Comic.get_preset_data("page", [])

	#var theme:Theme = preload("res://theme/root_theme.tres")
	#layer_depth = Comic.theme.get_constant("layer_depth", "Settings")
	#_default_line_layer = theme.get_constant("default_layer", "Frame")

	disable_3d = true
	msaa_2d = Viewport.MSAA_8X
	render_target_update_mode = SubViewport.UPDATE_ONCE
	background = ComicEditorBackground.new() if self is ComicEditorPage else ComicBackground.new()
	add_child(background)
	for i in Comic.LAYERS.size():
		var layer:ComicLayer = ComicLayer.new(i)
		layers.push_back(layer)
		add_child(layer)

	#print(">", bookmark)
	var file:FileAccess = FileAccess.open(str(Comic.DIR_STORY, bookmark if bookmark.contains("/") else str(bookmark, "/_"), ".", Comic.STORY_EXT), FileAccess.READ)
	var all_data = file.get_var()
	#print(all_data)
	if all_data == {}:
		# A newly created page
		all_data = {
			"page_data": {
				"file_version": Comic.STORY_FILE_VERSION,
			},
			"fragments": {
				"" : { "os":[{
				"otype": "line",
				"oid": 0,
				"points": [Vector2.ZERO, Vector2(Comic.size.x, 0), Comic.size, Vector2(0, Comic.size.y),Vector2.ZERO],
				"presets": ["page_border"],
				}] }
			}
		}
#	print(all_data)
	# CONVERSION ---------------------------------------------------------------
	# This section is for converting older story file formats to the current one, on load.
	# --------------------------------------------------------------------------

	_data = all_data.page_data
	RenderingServer.set_default_clear_color(bg_color)

	for key in all_data.fragments:
		add_fragment(key, all_data.fragments[key])
	file.close()
	
	if not self is ComicEditorPage:
		Comic.book.has_unsaved_changes = true
		# Set up auto-save - it will happen on _process
		if auto_save and Comic.book.auto_save_slot:
			save_slot = 0

func _process(_delta:float):
	if save_slot > -1:
		Comic.save_savefile(save_slot)
		save_slot = -1
	if load_slot > -1:
		Comic.load_savefile(load_slot)
		load_slot = -1

func add_fragment(key:String, fragment:Dictionary):
#	print("Adding fragment: ", key)
	# Only include the fragment if show returns true (or if it's the base fragment with key == "")
	if key == "" or Comic.parse_bool_string(Comic.execute_embedded_code(fragment.show)):
		for o_data in fragment.os:
			o_data.fragment = key
			add_o(o_data)

func add_o(o_data:Dictionary):
	var o:Variant
	match o_data.otype:
		"balloon":
			o = ComicBalloon.new(o_data, self)
			layers[o.layer].add_child(o)
		"button":
			o = ComicButton.new(o_data, self)
			Comic.book.buttons_container.add_child(o)
			for child in Comic.book.buttons_container.get_children():
				if child != o and child.order > o.order:
					Comic.book.buttons_container.move_child(o, child.get_index())
					break
		"hotspot":
			o = ComicHotspot.new(o_data, self)
			Comic.book.hotspots_container.add_child(o)
		"image":
			o = ComicImage.new(o_data, self)
			layers[o.layer].add_child(o)
		"line":
			o = ComicLine.new(o_data, self)
			layers[o.layer].add_child(o)
		"label":
			o = ComicKaboom.new(o_data, self)
			layers[o.layer].add_child(o)
		"note":
			if o_data.has("content"):
				Comic.parse_hidden_string(o_data.content)

func rebuild_lookups():
	# Rather than attempt to maintain lookups through all the various possibilities of editor actions, undoing, and redoing, we just rebuild them after we perform any such action.
	# Clear out old tail_backlinks and remake them
	for oid in os:
		if os[oid] is ComicBalloon and os[oid].get_parent() != null:
			os[oid].tail_backlinks.clear()
	for oid in os:
		if os[oid] is ComicBalloon and os[oid].get_parent() != null:
			var tails_to_remove:Array = []
			for tail_oid in os[oid].tail_data:
				var tail_data:Dictionary = os[oid].tail_data[tail_oid]
				if tail_data.linked:
					# Add the backlink
					os[tail_data.end_oid].tail_backlinks.push_back(Vector2i(oid, tail_data.oid))
			for tail_oid in tails_to_remove:
				os[oid].tail_data.erase(tail_oid)

func rebuild(rebuild_sub_objects:bool = true):
	background.rebuild()
	if rebuild_sub_objects:
		rebuild_lookups()
		for oid in os:
			if os[oid].has_method("rebuild") and os[oid].get_parent() != null:
				os[oid].rebuild(true)

func redraw(rebuild_lookups_first:bool = false):
	if rebuild_lookups_first:
		rebuild_lookups()
	for layer in layers:
		layer.queue_redraw()
	Comic.book.page.render_target_update_mode = SubViewport.UPDATE_ONCE

func make_oid() -> int:
	#We use os as unique, immutable identifiers for objects that are unique within a view
	last_oid += 1
	while os.has(last_oid):
		last_oid += 1
	return last_oid
	
func activate():
	match action:
		ComicButton.Action.GO:
			Comic.book.page_go(action_bookmark)
		ComicButton.Action.BACK:
			Comic.book.page_back()
		ComicButton.Action.NEXT:
			Comic.book.page_next()
		ComicButton.Action.PREVIOUS:
			Comic.book.page_previous()
		ComicButton.Action.VISIT:
			Comic.book.page_visit(action_bookmark)
		ComicButton.Action.RETURN:
			Comic.book.page_return()
		ComicButton.Action.PARSE_COMMANDS:
			Comic.parse_hidden_string(action_commands)

func enter_hotspot(hotspot:ComicHotspot):
	if not hovered_hotspots.has(hotspot):
		hovered_hotspots.push_back(hotspot)
		if hotspot.change_cursor:
			background.set_default_cursor_shape(Control.CURSOR_POINTING_HAND)

func exit_hotspot(hotspot:ComicHotspot):
	hovered_hotspots.erase(hotspot)
	if hotspot.change_cursor:
		var change_cursor = false
		for hovered_hotspot in hovered_hotspots:
			if hovered_hotspot.change_cursor:
				change_cursor = true
				break
		if not change_cursor:
			background.set_default_cursor_shape(Control.CURSOR_ARROW)

# ------------------------------------------------------------------------------

func is_default(key:Variant) -> bool:
	return _data_get(key) == _default_data[key]

func clear_data(key:Variant):
	_data.erase(key)

func _data_get(key:Variant):
	return _data.get(key, _default_data[key])

func _data_set(key:Variant, value:Variant):
	if value == _default_data[key]:
		_data.erase(key)
	else:
		_data[key] = value
