class_name ComicEditorPage
extends ComicPage

func _init(bookmark:String):
	super(bookmark)
	var layer:ComicLayer = ComicWidgetLayer.new("Widgets", INF)
	layers.push_back(layer)
	add_child(layer)

func add_click_line(line:String):
	super(line)
	background.mouse_default_cursor_shape = Control.CURSOR_ARROW

func get_save_data() -> Array:
	#TODO: Save multiple fragments and logic
	var save_data:Array = []
	var base_fragment:Dictionary = { "os":[] }
	save_data.push_back(base_fragment)	
	for oid in os:
		# Check that the object still exists, and is part of the scene tree
		if os[oid] != null and os[oid].get_parent() != null:
			base_fragment.os.push_back(os[oid].data)
	return save_data

func add_o(data:Dictionary) -> Variant:
	var o:Variant
	match data.otype:
		"balloon":
			o = ComicEditorBalloon.new(data, self)
		"line":
			o = ComicEditorLine.new(data, self)
		"label":
			o = ComicEditorLabel.new(data, self)
	get_layer(o.layer).add_child(o)
	return o

func add_balloon(data:Dictionary = {}):
	data.anchor = ComicEditor.snap(Vector2(Comic.book.menu.position))
	var balloon:ComicEditorBalloon = ComicEditorBalloon.new(data, self)
	rebuild_lookups()
	if data.get("with_tail"):
		var tail_data:Dictionary = { "oid": Comic.book.page.make_oid() }
		data.tails[tail_data.oid] = tail_data
		data.erase("with_tail")
	balloon.rebuild(true)

	Comic.book.add_undo_step([ComicReversionParent.new(balloon, null)])
	rebuild_lookups()

func add_line(data:Dictionary = {}):
	data.otype = "line"
	if not data.has("points"):
		data.points = [Comic.book.snap_and_contain(Vector2(Comic.book.menu.position.x,0)), Comic.book.snap_and_contain(Vector2(Comic.book.menu.position.x,Comic.size.y))]
	var line:ComicLine = Comic.book.page.add_o(data)
	Comic.book.add_undo_step([ComicReversionParent.new(line, null)])
	redraw()

func add_label(data:Dictionary = {}):
	data.otype = "label"
	data.anchor = ComicEditor.snap(Vector2(Comic.book.menu.position))
	var label:ComicLabel = Comic.book.page.add_o(data)
	label.rebuild(true)

	Comic.book.add_undo_step([ComicReversionParent.new(label, null)])
	redraw()

func redraw(rebuild_lookups_first:bool = false):
	if rebuild_lookups_first:
		rebuild_lookups()
	for layer in layers:
		layer.queue_redraw()
	Comic.book.page.render_target_update_mode = SubViewport.UPDATE_ONCE

func rebuild_widgets():
	if Comic.book.selected_element != null and Comic.book.selected_element.has_method("rebuild_widgets"):
		Comic.book.selected_element.rebuild_widgets()
	else:
		layers[-1].clear()

func get_o_at_point(global_position:Vector2, type:Variant = Node, ignore:Variant = null) -> Variant:
	# We start at the top-most non-widget layer and work our way down until we find an object containing the point.
	for i in range(Comic.book.page.layers.size() - 2, -1, -1):
		for child in Comic.book.page.layers[i].get_children():
			
#			if child is ComicBalloon and child != ignore and child.get_global_rect().has_point(global_position):
			if is_instance_of(child, type) and child.has_method("has_point") and child != ignore and child.has_point(global_position):
				return child
	return null
