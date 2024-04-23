class_name ComicEditor
extends ComicBook

enum MenuCommand {
	# Add
	ADD_BALLOON,
	ADD_CAPTION,
	ADD_LINE,
	ADD_KABOOM,

	ADD_BUTTON,
	ADD_HOTSPOT,

	ADD_NOTE,

	# Layers
	PUSH_TO_BACK,
	PUSH,
	PULL,
	PULL_TO_FRONT,

	#Size
	TOGGLE_COLLAPSE,
	TOGGLE_WIDTH_CONTROL,
	TOGGLE_HEIGHT_CONTROL,
	TOGGLE_MARGINS_CONTROL,
	TOGGLE_BOX_SCALE_CONTROL,

	# Balloon
	ADD_TAIL,

	# Anchors
	ANCHOR_TL,
	ANCHOR_L,
	ANCHOR_BL,
	ANCHOR_T,
	ANCHOR_C,
	ANCHOR_B,
	ANCHOR_TR,
	ANCHOR_R,
	ANCHOR_BR,

	# Used in more than one widget
	OPEN_PROPERTIES,
	DELETE,
	DEFAULT,
	RANDOMIZE,
	TOGGLE,
	ADD_PART,
	DELETE_PART,
	
	# Tail Start and Tail End Widgets

	#Background
	CHANGE_BACKGROUND,
	#TODO: Test these codes on mac
	UNDO = 268435546, # Ctrl+Z
	REDO = 301989978, # Shift+Ctrl+Z
	SAVE = 268435539, # Ctrl+S
	SAVE_AND_QUIT = 301989971, # Ctrl+Shift+S
	QUIT_WITHOUT_SAVING = 268435537, # Ctrl + Q
}

const DIR_ICONS:String = "res://addons/icbm_editor/theme/icons/"
const SETTINGS_PATH:String = "user://editor_settings.cfg"
const MAX_UNDO_STEPS:int = 50

var menu:PopupMenu
var popup_target:Control
var _page_keys:Array
var menu_action_position:Vector2
var _grabbed_element:Control
var _grab_offset:Vector2

var undo_steps:Array
var redo_steps:Array

@export var properties_panel:PanelContainer
@export var balloon_properties:ComicEditorBalloonProperties
@export var button_properties:ComicEditorButtonProperties
@export var kaboom_properties:ComicEditorKaboomProperties
@export var page_properties:ComicEditorPageProperties
# Probably don't need a property panel for lines?
# Maybe try to avoid property panels altogether?!

# Editor Settings
var snap_positions:bool = true
var angle_snap:float = TAU * 5.0 / 360.0
var distance_snap:float = 1

# ------------------------------------------------------------------------------

var open_properties:ComicEditorProperties:
	get:
		return open_properties
	set(value):
		if open_properties != value:
			if open_properties != null:
				open_properties.hide()
			open_properties = value
			if open_properties == null:
				properties_panel.hide()
			else:
				open_properties.prepare()
				open_properties.show()
				properties_panel.show()

var selected_element:Control:
	get:
		return selected_element
	set(value):
		print("SELECTED ", value)
		open_properties = null
		if selected_element != value:
			selected_element = value
			page.redraw()
			page.rebuild_widgets()

# ------------------------------------------------------------------------------

func _init():
	super()
	menu = ComicEditorPopupMenu.new()
	add_child(menu)
	menu.size = Vector2.ZERO
	menu.id_pressed.connect(_on_menu_item_pressed)
#	menu.mouse_passthrough = true
	mouse_filter = Control.MOUSE_FILTER_PASS

func _ready():
	super()
	get_window().title = str("ICBM Visual Editor: ", bookmark)

func open_menu(target:Control, pos:Vector2):
	open_properties = null
	# Open the right-click menu
	popup_target = target
	menu.clear()
	menu.size = Vector2.ZERO
	for child in menu.get_children():
		if child is PopupMenu:
			menu.remove_child(child)
			child.queue_free()
	if target.has_method("add_menu_items"):
		target.add_menu_items(menu)
		
	if pos.x + menu.size.x > get_window().size.x:
		pos.x -= menu.size.x
	if pos.y + menu.size.y > get_window().size.y:
		pos.y -= menu.size.y
	menu.position = pos
	menu.popup()
	
func _on_menu_item_pressed(id:int):
	popup_target.menu_command_pressed(id)

func left_clicked(target:Control, _event:InputEvent):
	selected_element = target

func double_clicked(target:Control, _event:InputEvent):
	if target.has_method("menu_command_pressed"):
		target.menu_command_pressed(MenuCommand.OPEN_PROPERTIES)

func right_clicked(target:Control, event:InputEvent):
	if not target is ComicWidget:
		#For widgets, the owner is already selected, and we don't want to change that.
		selected_element = target
	Comic.book.open_menu(target, get_viewport().get_mouse_position())

func grab(control:Control, offset:Vector2):
	_grabbed_element = control
	_grab_offset = offset

func _input(event:InputEvent):
	#NOTE: super() is not called - we don't want the normal reader input events.
	pass

func _gui_input(event:InputEvent):
	if _grabbed_element != null:
		if event is InputEventMouseMotion:
			_grabbed_element.dragged(get_viewport().get_mouse_position() - _grab_offset)
		elif event is InputEventMouseButton and event.is_released():
			_grabbed_element.dropped(get_viewport().get_mouse_position() - _grab_offset)
			_grabbed_element = null

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		match event.get_keycode_with_modifiers():
			MenuCommand.REDO:
				redo()
			MenuCommand.UNDO:
				undo()
			MenuCommand.SAVE:
				save()
			MenuCommand.SAVE_AND_QUIT:
				save(true)
			MenuCommand.QUIT_WITHOUT_SAVING:
				Comic.request_quit()
			_:
				if selected_element != null and selected_element.has_method("_on_key_pressed"):
					selected_element._on_key_pressed(event)
				else:
					print("Unhandled keypress: ", event.get_keycode_with_modifiers())

static func snap(pos:Variant) -> Variant:
	if Comic.book.snap_positions:
		if pos is Vector2:
			return pos.snapped(Vector2.ONE * Comic.px_per_unit)
		else:
			return snapped(pos, Comic.px_per_unit)
	return pos

static func snap_and_contain(pos:Vector2) -> Vector2:
	pos = pos.clamp(Vector2.ZERO, Comic.size)
	return snap(pos)

func add_undo_step(reversions:Array):
	undo_steps.push_back(reversions)
	while undo_steps.size() > MAX_UNDO_STEPS:
		# We've exceeded the undo buffer. Pop a step off the FRONT and don't forget to clean up.
		clean_up_reversions_step(undo_steps.pop_front())
	# Clear the redo steps, but clean them up, first
	for step in redo_steps:
		clean_up_reversions_step(step)
	redo_steps.clear()

func last_undo_matched(o:Control, key:String) -> bool:
	# Checks if the last undo step was a single reversion data change of the given control, and the data in the given key was changed
	# Used to avoid adding multiple undo steps for small sequential changes, like every letter of a text change, or every step of a keyboard-bump move
	return undo_steps.size() > 0 and undo_steps[-1].size() == 1 and undo_steps[-1][0] is ComicReversionData and undo_steps[-1][0].o == o and undo_steps[-1][0].data.get(key) != o.data.get(key)

func undo():
	if undo_steps.size() > 0:
		selected_element = null
		var undo_reversions:Array = undo_steps.pop_back()
		var redo_reversions:Array = []
		while undo_reversions.size() > 0:
			redo_reversions.push_back(undo_reversions.pop_back().apply())
		redo_steps.push_back(redo_reversions)
		page.rebuild_widgets()
	#TODO: Else play an unhappy thunk

func redo():
	if redo_steps.size() > 0:
		selected_element = null
		var redo_reversions:Array = redo_steps.pop_back()
		var undo_reversions:Array = []
		while redo_reversions.size() > 0:
			undo_reversions.push_back(redo_reversions.pop_back().apply())
		undo_steps.push_back(undo_reversions)
		page.rebuild_widgets()
	#TODO: Else play an unhappy thunk

func clean_up_reversions_step(a:Array, is_redo_step:bool=false):
	for reversion in a:
		clean_up_reversion(reversion, is_redo_step)

func clean_up_reversion(reversion:ComicReversion, is_redo_step:bool):
	# If we're clearing out an undo reversion, and the reversion is a clear parent, and the object is currently unparented, then the object was deleted and we're now forgetting about it - free the object.
	# OR if we're clearing out a redo reversion, and the reversion is a set parent, and the object is currently unparented, then the object was added and we're now forgetting about it - free the object.
	if reversion is ComicReversionParent and reversion.o.get_parent() == null and is_redo_step != (reversion.parent == null):
		Comic.book.page.os.erase(reversion.o.oid)
		reversion.o.queue_free()

func save(quit_after_saving:bool = false):
	var save_data:Dictionary = page.get_save_data()
	#print(save_data)

	# There are some properties of page.data that we don't want to save - we deal with them and erase them, first.
	var new_bookmark = page.bookmark
	if save_data.page_data.has("new_name"):
		# This doesn't necessarily mean that there's a new name, just that the new_name property exists because page properties was opened - it might be the same as the existing name.
		new_bookmark = save_data.page_data.new_name
		save_data.page_data.erase("new_name")
		if save_data.page_data.has("new_chapter"):
			# This is a non-title page
			new_bookmark = str(save_data.page_data.new_chapter, "/", new_bookmark)
			save_data.page_data.erase("new_chapter")

	# Do the save.
	var file:FileAccess = FileAccess.open(str(Comic.DIR_STORY, bookmark if bookmark.contains("/") else str(bookmark, "/_"), ".txt"), FileAccess.WRITE)
	file.store_var(save_data)
	file.close()
	page.background.save()
	
	# Now do the rename
	if page.bookmark != new_bookmark:
		# We've changed something, and need to rename or move files.
		new_bookmark = get_unique_bookmark(new_bookmark)
		if page.bookmark.contains("/"):
			rename_page(page.bookmark, new_bookmark)
		else:
			rename_chapter(page.bookmark, new_bookmark)

		# We update the page bookmark so that later operations (like promote) have the new one.
		page.bookmark = new_bookmark
	
	# Update the last_bookmark editor setting, in case we changed the bookmark
	save_setting("last_bookmark", page.bookmark)
	
	has_unsaved_changes = false
	if quit_after_saving:
		Comic.quit()

func promote():
	save(false)
	if page.bookmark.contains("/"):
		# page - promote to title
		var chapter:String = page.bookmark.split("/")[0]
		rename_page(chapter, get_unique_bookmark(str(chapter, "/old_title_page")))
		rename_page(page.bookmark, chapter)
	else:
		# chapter - promote to start
		rename_chapter("start", get_unique_bookmark("old_start_chapter"))
		rename_chapter(page.bookmark, "start")
	Comic.quit()

static func rename_chapter(old_bookmark:String, new_bookmark:String):
	var dir:DirAccess = DirAccess.open(Comic.DIR_STORY)
	dir.rename(old_bookmark, new_bookmark)
	update_links(old_bookmark, new_bookmark)

static func rename_page(old_bookmark:String, new_bookmark:String):
	#NOTE: This method doesn't test new_bnookmark is unique. That should be done before calling this method.
	var dir:DirAccess = DirAccess.open(Comic.DIR_STORY)
	update_links(old_bookmark, new_bookmark, false)
	# If either page is a title page, we add "/_" to it to get the file name
	if not old_bookmark.contains("/"):
		old_bookmark = str(old_bookmark, "/_")
	if not new_bookmark.contains("/"):
		new_bookmark = str(new_bookmark, "/_")
	dir.rename(str(old_bookmark, ".txt"), str(new_bookmark, ".txt"))
	for ext in Comic.IMAGE_EXT:
		if dir.file_exists(str(old_bookmark, ".", ext)):
			dir.rename(str(old_bookmark, ".", ext), str(new_bookmark, ".", ext))
			# Remove Godot's import file - image will be reimported at new location. (Doing this because I'm not sure if it's safe to move a .import)
			dir.remove(str(old_bookmark, ".", ext, ".import"))
			break

static func delete_page(bookmark:String):
	var dir:DirAccess = DirAccess.open(Comic.DIR_STORY)
	dir.remove(str(bookmark, ".txt"))
	for ext in Comic.IMAGE_EXT:
		if dir.file_exists(str(bookmark, ".", ext)):
			dir.remove(str(bookmark, ".", ext))
			dir.remove(str(bookmark, ".", ext, ".import"))
			break
	update_links(bookmark, "")

static func delete_chapter(bookmark:String):
	var dir:DirAccess = DirAccess.open(Comic.DIR_STORY)
	var path:String = str(Comic.DIR_STORY, bookmark)
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(str(path, "/", file))
	DirAccess.remove_absolute(path)
	if bookmark == "start":
		# Start chapter deleted - create a blank one
		ComicEditor.create_start_chapter()
	else:
		update_links(bookmark, "")

func delete():
	if page.bookmark.contains("/"):
		delete_page(bookmark)
	else:
		delete_chapter(bookmark)
	save_setting("last_bookmark", "start")
	Comic.quit()

static func update_links(from_bookmark:String, to_bookmark:String, entire_chapter:bool = true):
	#NOTE: if deleted, to_bookmark will be ""
	if entire_chapter and not from_bookmark.contains("/"):
		# We're updating links to any page in the whole chapter, not just links to the title page.
		print("TODO: Update links to whole chapter")
	else:
		print("TODO: Update links")

static func load_setting(key:String, default_value:Variant = null) -> Variant:
	var settings = _load_settings_file()
	return settings.get(key, default_value)

static func save_setting(key:String, value:Variant):
	var settings = _load_settings_file()
	settings[key] = value
	_save_settings_file(settings)

static func save_settings(dict:Dictionary):
	var settings = _load_settings_file()
	for key in dict:
		settings[key] = dict[key]
	_save_settings_file(settings)

static func _load_settings_file() -> Dictionary:
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		var settings:Dictionary = file.get_var()
		file.close()
		return settings
	return {}
	
static func _save_settings_file(settings:Dictionary):
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_var(settings)
	file.close()

func save_presets_file():
	var file = FileAccess.open(str(Comic.DIR_STORY, "presets.cfg"), FileAccess.WRITE)
	file.store_var(presets)
	file.close()

static func parse_text_edit(s:String) -> String:
	return s.replace("[br]", "\n").replace("[tab]","	")

static func unparse_text_edit(s:String) -> String:
	return s.replace("\n", "[br]").replace("	","[tab]")

static func create_start_chapter():
	var dir:DirAccess = DirAccess.open("res://")
	if not dir.dir_exists("story/start"):
		assert(dir.make_dir_recursive("story/start") == OK)
	if not FileAccess.file_exists(str(Comic.DIR_STORY, "start/_.txt")):
		var file:FileAccess = FileAccess.open(str(Comic.DIR_STORY, "start/_.txt"), FileAccess.WRITE)
		file.store_var({})
		file.close()

static func get_unique_bookmark(bookmark:String) ->String:
	var dir:DirAccess = DirAccess.open(Comic.DIR_STORY)
	if bookmark.contains("/"):
		# page
		if not dir.file_exists(str(bookmark, ".txt")):
			return bookmark
	else:
		# chapter
		if not dir.dir_exists(bookmark):
			return bookmark
	var elements:Array = bookmark.split("_")
	var i:int = int(elements[-1])
	if elements[-1] == str(i):
		# Last element is already numeric - remember it and remove it from the bookmark
		elements[-1] = ""
	else:
		# last element is not numeric - set i to 1 and add an underscore at the end of the bookmark
		i = 1
		elements.push_back("")
	bookmark = "_".join(elements)
	if bookmark.contains("/"):
		# page
		while dir.file_exists(str(bookmark, i, ".txt")):
			i += 1
	else:
		# chapter
		while dir.dir_exists(str(bookmark, i)):
			i += 1
	return str(bookmark, i)

func open_presets_manager(category:String):
	var popup = ComicEditorPresetsManager.new(category)
	Comic.add_child(popup)

