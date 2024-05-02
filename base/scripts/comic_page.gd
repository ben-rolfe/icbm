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
var data:Dictionary
var _default_data:Dictionary

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

#-------------------------------------------------------------------------------

func _init(_bookmark: String):
	bookmark = _bookmark
	name = bookmark.replace("/","__")

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

	var file:FileAccess = FileAccess.open(str(Comic.DIR_STORY, bookmark if bookmark.contains("/") else str(bookmark, "/_"), ".txt"), FileAccess.READ)
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

	#TODO: Update
	if not all_data.page_data.has("file_version"):
		for fragment in all_data.fragments:
			add_fragment(fragment)
	else:
		for fragment in all_data.fragments:
			add_fragment(all_data.fragments[fragment])
	file.close()

	data = all_data.page_data
	_default_data = _get_default_data()


func add_fragment(fragment:Dictionary):
	print("Adding fragment")
	#TODO: Cope with logic fragments and include fragments
	for o in fragment.os:
		add_o(o)

func add_o(o_data:Dictionary):
	var o:Variant
	match o_data.otype:
		"balloon":
			o = ComicBalloon.new(o_data, self)
			layers[o.layer].add_child(o)
		"button":
			o = ComicButton.new(o_data, self)
			Comic.book.buttons_container.add_child(o)
		"line":
			o = ComicLine.new(o_data, self)
			layers[o.layer].add_child(o)
		"label":
			o = ComicKaboom.new(o_data, self)
			layers[o.layer].add_child(o)
		"note":
			if o_data.has("text"):
				Comic.parse_hidden_string(o_data.text)

func rebuild_lookups():
	# Rather than attempt to maintain lookups through all the various possibilities of editor actions, undoing, and redoing, we just rebuild them after we perform any such action.

	# Clear out old tail_backlinks and remake them
	for oid in os:
		if os[oid] is ComicBalloon:
			os[oid].tail_backlinks.clear()
	for oid in os:
		if os[oid] is ComicBalloon:
			var tails_to_remove:Array = []
			for tail_oid in os[oid].data.tails:
				var tail_data:Dictionary = os[oid].data.tails[tail_oid]
				if tail_data.linked:
					# Add the backlink
					os[tail_data.end_oid].tail_backlinks.push_back(Vector2i(oid, tail_data.oid))
			for tail_oid in tails_to_remove:
				os[oid].data.tails.erase(tail_oid)

func rebuild(rebuild_sub_objects:bool = true):
	background.rebuild()
	if rebuild_sub_objects:
		rebuild_lookups()
		for oid in os:
			if os[oid].has_method("rebuild"):
				os[oid].rebuild(true)

#func get_layer(i:int) -> ComicLayer:
	#i = clampi(i,-layer_depth,layer_depth)
	#return layers[i + layer_depth]

#func add_click_line(line:String):
	#_click_lines.push_back(line)
	#background.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
#
#func activatebackground_button():
	#if _click_lines.size() > 0:
		#Comic.book.read_lines(_click_lines, self)

func make_oid() -> int:
	#We use os as unique, immutable identifiers for objects that are unique within a view
	last_oid += 1
	while os.has(last_oid):
		last_oid += 1
	return last_oid
	
#func make_ref() -> String:
	#last_ref += 1
	#while refs.has(str("_", last_ref)):
		#last_ref += 1
	#return str("_", last_ref)
		

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

# ------------------------------------------------------------------------------

func _data_get(key:Variant):
	return data.get(key, _default_data[key])

func _data_set(key:Variant, value:Variant):
	if value == _default_data[key]:
		data.erase(key)
	else:
		data[key] = value

#TODO: Currently this doesn't need to be a method, and _default_data could be a const. If that doesn't change, fix it.
func _get_default_data() -> Dictionary:
	var r:Dictionary = {
		"action": ComicButton.Action.NEXT,
		"action_bookmark": "",
		"action_commands": "",
	}
	return r
