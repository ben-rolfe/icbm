class_name ComicPage
extends SubViewport

var bg_path:String
var background:ComicBackground
var layers:Array[ComicLayer] = []

var layer_depth:int

var bookmark:String

var last_oid:int = -1
var os = {}
#var balloons = {}
#var labels = {}
#var last_ref:int = -1
#var refs = {}

func _init(_bookmark: String):
	bookmark = _bookmark
	name = bookmark.replace("/","__")

	#var theme:Theme = preload("res://theme/root_theme.tres")
	layer_depth = Comic.theme.get_constant("layer_depth", "Settings")
	#_default_line_layer = theme.get_constant("default_layer", "Frame")

	disable_3d = true
	msaa_2d = Viewport.MSAA_8X
	render_target_update_mode = SubViewport.UPDATE_ONCE
	background = ComicEditorBackground.new() if self is ComicEditorPage else ComicBackground.new()
	add_child(background)
	for i in range(-layer_depth, layer_depth + 1):
		var layer:ComicLayer = ComicLayer.new(str(i), i)
		layers.push_back(layer)
		add_child(layer)

	var file:FileAccess = FileAccess.open(str(Comic.DIR_STORY, bookmark if bookmark.contains("/") else str(bookmark, "/_"), ".txt"), FileAccess.READ)
	var page_data = file.get_var()
	if page_data == []:
		# A newly created page
		page_data = get_default_data()
#	print(page_data)
	for fragment in page_data:
		add_fragment(fragment)
	file.close()

func add_fragment(fragment:Dictionary):
	print("Adding fragment")
	#TODO: Cope with logic fragments and include fragments
	for o in fragment.os:
		add_o(o)

func add_o(data:Dictionary):
	var o:Variant
	match data.otype:
		"balloon":
			o = ComicBalloon.new(data, self)
		"line":
			o = ComicLine.new(data, self)
		"label":
			o = ComicLabel.new(data, self)
		"note":
			if data.has("text"):
				if OS.is_debug_build():
					print(Comic.execute(data.text))
				else:
					Comic.execute(data.text)
	if o != null:
		get_layer(o.layer).add_child(o)

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

func rebuild():
	background.rebuild()
	rebuild_lookups()
	for oid in os:
		if os[oid].has_method("rebuild"):
			os[oid].rebuild(true)

func get_layer(i:int) -> ComicLayer:
	i = clampi(i,-layer_depth,layer_depth)
	return layers[i + layer_depth]

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
		
func get_default_data() -> Array:
	# Add the default frame
	return [{ "os":[{
		# We draw the outside frame at double width, so that one full width is shown within the page.
		"otype": "line",
		"oid": 0,
		"fill_width": Comic.theme.get_constant("fill_width", "Frame") * 2,
		"points": [Vector2.ZERO, Vector2(Comic.size.x, 0), Comic.size, Vector2(0, Comic.size.y),Vector2.ZERO],
	}] }]
