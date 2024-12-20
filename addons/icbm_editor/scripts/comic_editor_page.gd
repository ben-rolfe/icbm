class_name ComicEditorPage
extends ComicPage

var new_name:String:
	get:
		return _data.get("new_name", bookmark.split("/")[1] if bookmark.contains("/") else bookmark)
	set(value):
		_data.new_name = value

var new_chapter:String:
	get:
		return _data.get("new_chapter", bookmark.split("/")[0])
	set(value):
		_data.new_chapter = value

func _init(bookmark:String):
	super(bookmark)
	var layer:ComicLayer = ComicWidgetLayer.new(Comic.LAYERS.size())
	layers.push_back(layer)
	add_child(layer)
	background.mouse_default_cursor_shape = Control.CURSOR_ARROW

func get_save_data() -> Dictionary:
	#TODO: Save multiple fragments and logic
	var save_data:Dictionary = {
		"page_data": _data.duplicate(),
		"fragments":{},
	}
	# We remove the fragments dictionary from the page data, since we're creating a new dictionary of fragments and the data of the objects they contain
	save_data.page_data.erase("fragments")
	
	save_data.fragments[""] = { "os":[] } # We add the base fragment first
	for key in _data.fragments:
		save_data.fragments[key] = _data.fragments[key].duplicate()
		save_data.fragments[key].os = []
	
	for oid in os:
		# Check that the object still exists, and is part of the scene tree (i.e. hasn't been deleted)
		if os[oid] != null and os[oid].get_parent() != null:
			var o_data:Dictionary = os[oid].get_save_data()
			o_data.erase("fragment")
			save_data.fragments[os[oid].fragment].os.push_back(o_data)
	
	return save_data

func add_fragment(key:String, fragment:Dictionary):
	if not _data.has("fragments"):
		# In the editor, we store the fragments in the page data, which allows for easy integration with the undo/redo system.
		# We don't store objects IN the fragments, like we do in the save file - rather, the objects have a fragment property
		# On save, we remove the fragments dictionary from the page data, and create a different fragments dictionary, which actually contains the save data for its objects
		_data.fragments = {}
	if key != "":
		_data.fragments[key] = fragment
	for o_data in fragment.os:
		o_data.fragment = key
		add_o(o_data)
	# Now that we've added the objects, we remove the object data from the fragment - we'll add it back on save.
	fragment.erase("os")

func add_o(data:Dictionary) -> Variant:
	var o:Variant
	if data.has("otype"):
		match data.otype:
			"balloon":
				o = ComicEditorBalloon.new(data, self)
				layers[o.layer].add_child(o)
			"button":
				o = ComicEditorButton.new(data, self)
				Comic.book.buttons_container.add_child(o)
				for child in Comic.book.buttons_container.get_children():
					if child != o and child.order > o.order:
						Comic.book.buttons_container.move_child(o, child.get_index())
						break
			"hotspot":
				o = ComicEditorHotspot.new(data, self)
				Comic.book.hotspots_container.add_child(o)
			"image":
				o = ComicEditorImage.new(data, self)
				layers[o.layer].add_child(o)
			"line":
				o = ComicEditorLine.new(data, self)
				layers[o.layer].add_child(o)
			"label":
				o = ComicEditorKaboom.new(data, self)
				layers[o.layer].add_child(o)
			"note":
				o = ComicEditorNote.new(data, self)
				layers[o.layer].add_child(o)
			"line_edit":
				o = ComicEditorLineEdit.new(data, self)
				Comic.book.gui_container.add_child(o)
		return o
	else:
		printerr("No otype in data: ", data)
		return null

func add_balloon(data:Dictionary = {}):
	data.anchor = ComicEditor.snap(Vector2(Comic.book.menu.position))
	var balloon:ComicEditorBalloon = ComicEditorBalloon.new(data, self)
	rebuild_lookups()
	if data.get("with_tail"):
		var tail_data:Dictionary = { "oid": Comic.book.page.make_oid() }
		balloon.tail_data[tail_data.oid] = tail_data
		balloon.clear_data("with_tail")
	balloon.rebuild(true)

	Comic.book.add_undo_step([ComicReversionParent.new(balloon, null)])
	rebuild_lookups()

func add_button(data:Dictionary = {}):
	var button:ComicEditorButton = ComicEditorButton.new(data, self)
	Comic.book.buttons_container.add_child(button)
	Comic.book.add_undo_step([ComicReversionParent.new(button, null)])

func add_line(data:Dictionary = {}):
	data.otype = "line"
	if not data.has("points"):
		data.anchor = Comic.book.snap_and_contain(Vector2(Comic.book.menu.position.x,0))
		data.points = [Vector2.ZERO, Comic.book.snap_and_contain(Vector2(Comic.book.menu.position.x,Comic.size.y)) - data.anchor]
	var line:ComicLine = add_o(data)
	Comic.book.add_undo_step([ComicReversionParent.new(line, null)])
	redraw()

func add_kaboom(data:Dictionary = {}):
	data.otype = "label"
	data.anchor = ComicEditor.snap(Vector2(Comic.book.menu.position))
	var kaboom:ComicKaboom = add_o(data)
	kaboom.rebuild(true)

	Comic.book.add_undo_step([ComicReversionParent.new(kaboom, null)])
	redraw()

func add_note(data:Dictionary = {}):
	data.otype = "note"
	data.anchor = ComicEditor.snap(Vector2(Comic.book.menu.position))
	var note:ComicEditorNote = add_o(data)
	note.rebuild(true)

	Comic.book.add_undo_step([ComicReversionParent.new(note, null)])
	redraw()

func add_hotspot(data:Dictionary = {}):
	data.otype = "hotspot"
	data.anchor = ComicEditor.snap(Vector2(Comic.book.menu.position))
	var hotspot:ComicEditorHotspot = add_o(data)
	hotspot.rebuild(true)

#	Comic.book.add_undo_step([ComicReversionParent.new(hotspot, null)])
	redraw()

func add_image(data:Dictionary = {}):
	data.otype = "image"
	#if not data.has("anchor"):
	data.anchor = ComicEditor.snap(Vector2(Comic.book.menu.position))
	var image:ComicEditorImage = add_o(data)
	image.rebuild(true)

	Comic.book.add_undo_step([ComicReversionParent.new(image, null)])
	redraw()

func add_line_edit(data:Dictionary = {}):
	data.otype = "line_edit"
	data.anchor = ComicEditor.snap(Vector2(Comic.book.menu.position))
	var line_edit:ComicEditorLineEdit = ComicEditorLineEdit.new(data, self)
	Comic.book.gui_container.add_child(line_edit)
	Comic.book.add_undo_step([ComicReversionParent.new(line_edit, null)])

func rebuild_widgets():
	if Comic.book.selected_element != null and Comic.book.selected_element.has_method("rebuild_widgets"):
		Comic.book.selected_element.rebuild_widgets()
	else:
		layers[-1].clear()

func get_o_at_point(global_position:Vector2, type:Variant = Node, ignore:Variant = null) -> Variant:
	# We start at the top-most non-widget layer and work our way down until we find an object containing the point.
	for i in range(Comic.book.page.layers.size() - 2, -1, -1):
		var children:Array = Comic.book.page.layers[i].get_children()
		# When overlapping, we want more recently added objects to take priority, primarily so that when copy-pasting and moving an object, the newly added one gets moved.
		children.reverse()
		for child in children:
			if is_instance_of(child, type) and child.is_visible() and child.has_method("has_point") and child != ignore and child.has_point(global_position):
				return child
	return background

func remove_o_from_fragment(o:Variant):
	#TODO: Create undo reversion
	var fragment = o.fragment
	o.fragment = ""
	# Check if fragment is empty, and if so, delete it.
	var empty:bool = true
	for oid in os:
		if os[oid].fragment == fragment:
			empty = false
			break
	if empty:
		_data.fragments.erase(fragment)

func rename_fragment(from:String, to:String):
	#TODO: Create undo reversion
	if _data.fragments.has(from) and not _data.fragments.has(to):
		for oid in os:
			if os[oid].fragment == from:
				os[oid].fragment = to
		_data.fragments[to] = _data.fragments[from]
		_data.fragments.erase(from)
		_data.fragments = Comic.sort_dictionary(_data.fragments)

func new_fragment(key:String, initial_o:Variant):
	#TODO: Create undo reversion
	if not _data.fragments.has(key):
		_data.fragments[key] = {
			"show": "true", # This value is intentionally a string
			"show_in_editor": true,
		}
	initial_o.fragment = key

func delete_fragment(key:String):
	#TODO: create undo reversion
	_data.fragments.erase(key)
	for oid in os:
		if os[oid].fragment == key:
			os[oid].fragment = ""
	
func redraw(rebuild_lookups_first:bool = false):
	if rebuild_lookups_first:
		rebuild_lookups()
	# Since we're in the editor, we don't care about whether the object will be shown or hidden in the game, we want to see it here (it unless it's part of a fragment that we've elected not to show in the editor.)
	for oid in os:
		if os[oid].fragment == "" or _data.fragments[os[oid].fragment].show_in_editor:
			os[oid].show()
		else:
			os[oid].hide()
	for layer in layers:
		layer.queue_redraw()
	Comic.book.page.render_target_update_mode = SubViewport.UPDATE_ONCE

func import_new_image(path:String):
	add_image({"new_path":path})
