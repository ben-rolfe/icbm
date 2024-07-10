class_name ComicBook
extends Control

@export var page_container:SubViewportContainer
@export var hotspots_container:Node2D
@export var buttons_container:BoxContainer

var aliases:Dictionary = {}
var change_page:bool
var default_balloon_layer:int
var history:Array = []
var _history_size:int
var page:ComicPage
var has_unsaved_changes:bool
var pages:Dictionary
var bookmarks:PackedStringArray
var presets:Dictionary

var timers:Array = []
var click_counters:Array = []

var _data:Dictionary
# ------------------------------------------------------------------------------

var bookmark:String:
	get:
		return Comic.vars._bookmarks[-1]
	set(value):
		Comic.vars._bookmarks[-1] = value

#NOTE: Unlike other Comic objects, we don't have _default_data, and we don't have _data_get and _data_set methods.
# Instead, ComicBook's _data is directly pulled from the default preset. 
var auto_save_slot:bool:
	get:
		return _data["auto_save_slot"]
	set(value):
		_data["auto_save_slot"] = value

var manual_save_slots:bool:
	get:
		return _data["manual_save_slots"]
	set(value):
		_data["manual_save_slots"] = value

# ------------------------------------------------------------------------------

func _init():
	Comic.book = self

	#Load the presets
	if FileAccess.file_exists(str(Comic.DIR_STORY, "presets.", Comic.STORY_EXT)):
		var file = FileAccess.open(str(Comic.DIR_STORY, "presets.", Comic.STORY_EXT), FileAccess.READ)
		presets = file.get_var()
		file.close()
		# Make sure that the loaded presets are compatible with the presets defined in Comic
		# (This will help avoid errors from old save files if the presets are changed between ICBM versions, or altered by a module)
		for preset_key in Comic.default_presets:
			if presets.has(preset_key):
				for property_key in Comic.default_presets[preset_key]:
					if not presets[preset_key].has(property_key):
						presets[preset_key][property_key] = Comic.default_presets[preset_key][property_key]
			else:
				presets[preset_key] = Comic.default_presets[preset_key]
	else:
		# Presets file doesn't exist - use default presets:
		presets = Comic.default_presets
	
	# We store data relating to the book as a whole in default book preset.
	_data = Comic.get_preset_data("book", [])
#	print(_data)

	_history_size = Comic.theme.get_constant("history_size", "Settings")
	default_balloon_layer = Comic.theme.get_constant("default_layer", "Balloon")
	pages = {"start":["_"]} # We begin with start in the dictionary, so that it will be at index 0.
	for chapter in Comic.natural_sort(DirAccess.get_directories_at(Comic.DIR_STORY)):
		if chapter != "start":
			pages[chapter] = ["_"] # We begin each chapter with the title page, so that it will be at index 0.
		for page_filename in Comic.natural_sort(DirAccess.get_files_at(str(Comic.DIR_STORY, chapter))):
			if page_filename.get_extension() == Comic.STORY_EXT and page_filename.get_basename().get_file() != "_":
				pages[chapter].push_back(page_filename.get_basename().get_file())
	for chapter in pages:
		for page_filename in pages[chapter]:
			if page_filename == "_":
				bookmarks.push_back(chapter) # Title page
			else:
				bookmarks.push_back(str(chapter, "/", page_filename))

func _ready():
#	read_story_directory()
	if OS.is_debug_build():
		start(Comic.config.get_value("editor", "bookmark", "start"))
		# We reset the bookmark to start, so that that will be open next time the game is run (unless changed by ComicEditorPlugin, in the meantime
		Comic.config.set_value("editor", "bookmark", "start")
	else:
		start()

func _unhandled_key_input(event):
	if event.is_action_pressed("ui_cancel"):
		# When escape is pressed, we bring up the right click menu for the background, which includes the quit option.
		# This behaviour might also be useful in the event that the user buries the background under other elements.
		ComicMenu.open()
	elif event.is_action_pressed("ui_fullscreen"):
		Comic.full_screen = not Comic.full_screen
	elif event.keycode == KEY_PRINT:
		# KEY_PRINT seems to work differently to other keys - it can't be set as an action.
		# Also, we don't get an event on key released, and the key pressed event has pressed = false
		screen_shot()
	elif event.is_action_pressed("ui_left"):
		back_if_allowed()
	elif event.is_action_pressed("ui_right"):
		page.activate()

func screen_shot():
	DirAccess.make_dir_absolute(Comic.DIR_SCREENSHOTS)
	get_viewport().get_texture().get_image().save_webp(Comic.DIR_SCREENSHOTS + Comic.vars._bookmarks[-1].replace("/","_") + ".webp")
	OS.shell_open(ProjectSettings.globalize_path(Comic.DIR_SCREENSHOTS))

func _process(delta:float):
	if change_page:
		_show_page()
	for i in range(timers.size() - 1, -1, -1):
		timers[i].t -= delta
		if timers[i].t < 0: 
			Comic.execute_embedded_code(timers[i].s)
			timers.remove_at(i)

func start(start_page:String = "start"):
	Comic.vars = { "_bookmarks": [start_page] }
	change_page = true

func left_clicked(target:CanvasItem, _event:InputEvent):
#	print(target)
	if target is ComicBackground:
		if click_counters.size() > 0:
			for i in range(click_counters.size() - 1, -1, -1):
				click_counters[i].clicks -= 1
				if click_counters[i].clicks <= 0: 
					Comic.execute_embedded_code(click_counters[i].s)
					click_counters.remove_at(i)
		else:
			page.activate()
	elif target is ComicHotspot:
		target.activate()

func right_clicked(target:CanvasItem, _event:InputEvent):
	if target is ComicBackground:
		back_if_allowed()
	#NOTE: We ignore right clicks on hotspots

func double_clicked(target:CanvasItem, event:InputEvent):
	# If we're not in the editor, we don't do anything special with a double-click - just treat it like a normal left click
	left_clicked(target, event)

# This is for back calls initiated by the user right clicking or pressing the left arrow key.
# Other ways of going back (such as a button or hotspot) don't test page.allow_back
func back_if_allowed():
	if page.allow_back:
		page_back()

func _show_page():
	change_page = false
	
	#Clear all non-persistent timers and counters on page change
	for i in range(timers.size() - 1, -1, -1):
		if not timers[i].has("persist"):
			timers.remove_at(i)
	for i in range(click_counters.size() - 1, -1, -1):
		if not click_counters[i].has("persist"):
			click_counters.remove_at(i)
			
	print("--- NEW PAGE ---")
	history.push_back(Comic.vars.duplicate(true))
	#print(history)
	while history.size() > _history_size:
		history.pop_front()
	# Buttons are not part of the page itself, so we need to clear them separately:
	for button in buttons_container.get_children():
		button.queue_free()
	if page != null:
		#TODO: Transitions?
		page.queue_free()
	if self is ComicEditor:
		page = ComicEditorPage.new(bookmark)		
	else:
		page = ComicPage.new(bookmark)
	page_container.add_child(page)
#	read_lines(_page_data[bookmark], page)
	if change_page:
		# If the page has changed while parsing the page lines, we don't display the page, we just immediately show the new one. 
		_show_page()
	else:
		page.rebuild()
		Comic.page_changed.emit(bookmark)

func page_back():
	if history.size() > 1:
		history.pop_back() # This is the vars history for the *current* page - we discard it.
		Comic.vars = history.pop_back()	#behind it is the vars history for the previous page. We remove it and load it into vars - changing the page will add it back to the history.
		print("Go back!")
		print(history)
		change_page = true

func page_go(_bookmark:String):
	bookmark = _bookmark
	change_page = true

func page_next():
	bookmark = get_relative_bookmark(bookmark, 1)
	change_page = true

func page_previous():
	bookmark = get_relative_bookmark(bookmark, -1)
	change_page = true

func page_return():
	if Comic.vars._bookmarks.size() > 1:
		Comic.vars._bookmarks.pop_back()
	else:
		printerr("Return was called when bookmarks contained only one value (perhaps visit hadn't been called or return was called multiple times)")
	change_page = true

func page_visit(_bookmark:String):
	Comic.vars._bookmarks.push_back(_bookmark)
	change_page = true

func get_relative_bookmark_index(from_key:String, offset:int) -> int:
	var index = bookmarks.find(from_key)
	if index == null:
		# We default to the title page.
		index = 0
	else:
		index = posmod(index + offset, bookmarks.size())
	return index

func get_relative_bookmark(from_key:String, offset:int) -> String:
	return bookmarks[get_relative_bookmark_index(from_key, offset)]

