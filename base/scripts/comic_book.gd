class_name ComicBook
extends Control

@export var page_container:SubViewportContainer
@export var buttons_container:BoxContainer
#@export var debug_bookmark:String = "start"

var aliases:Dictionary = {}
var change_page:bool
var default_balloon_layer:int
var history:Array = []
var _history_size:int
#var _page_data:Dictionary = {}
var vars:Dictionary
var page:ComicPage
var has_unsaved_changes:bool
var pages:Dictionary
var bookmarks:PackedStringArray
var presets:Dictionary
# ------------------------------------------------------------------------------

var bookmark:String:
	get:
		return vars._bookmarks[-1]
	set(value):
		vars._bookmarks[-1] = value

# ------------------------------------------------------------------------------

func _init():
	Comic.book = self

	#Load the presets
	if FileAccess.file_exists(str(Comic.DIR_STORY, "presets.cfg")):
		var file = FileAccess.open(str(Comic.DIR_STORY, "presets.cfg"), FileAccess.READ)
		presets = file.get_var()
		file.close()
	else:
		# Presets file doesn't exist - use default presets:
		presets = Comic.default_presets

	_history_size = Comic.theme.get_constant("history_size", "Settings")
	default_balloon_layer = Comic.theme.get_constant("default_layer", "Balloon")
	pages = {"start":["_"]} # We begin with start in the dictionary, so that it will be at index 0.
	for chapter in DirAccess.get_directories_at(Comic.DIR_STORY):
		if chapter != "start":
			pages[chapter] = ["_"] # We begin each chapter with the title page, so that it will be at index 0.
		for page_filename in DirAccess.get_files_at(str(Comic.DIR_STORY, chapter)):
			if page_filename.get_extension() == "txt" and page_filename.get_basename().get_file() != "_":
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
		start(ComicEditor.load_setting("bookmark", "start"))
		# We reset the bookmark to start, so that that will be open next time the game is run (unless changed by ComicEditorPlugin, in the meantime
		ComicEditor.save_setting("bookmark", "start")
	else:
		start("start")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("TODO: Open menu instead")
		get_tree().quit()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_PRINT:
				get_viewport().get_texture().get_image().save_webp("user://" + Comic.vars._bookmarks[-1].replace("/","_") + ".webp")
				OS.shell_open(ProjectSettings.globalize_path("user://"))
			#Key.KEY_SPACE, Key.KEY_RIGHT, Key.KEY_0, Key.KEY_KP_0:
				#page.activate_bg_button()
			Key.KEY_LEFT:
				page_back()

func _process(_delta:float):
	if change_page:
		_show_page()

func start(start_page:String):
	vars = { "_bookmarks": [start_page] }
	#TODO: Reinstate setup?
	#if _page_data.has("_setup"):
		#read_lines(_page_data._setup, self)
	change_page = true

func left_clicked(control:Control, _event:InputEvent):
	if control is ComicBackground:
		page.activate()

func right_clicked(control:Control, _event:InputEvent):
	if control is ComicBackground:
		page_back()

func _show_page():
	change_page = false
	print("--- NEW PAGE ---")
	history.push_back(vars.duplicate(true))
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

func page_back():
	if history.size() > 1:
		history.pop_back() # This is the vars history for the *current* page - we discard it.
		vars = history.pop_back()	#behind it is the vars history for the previous page. We remove it and load it into vars - changing the page will add it back to the history.
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
	if vars._bookmarks.size() > 1:
		vars._bookmarks.pop_back()
	else:
		printerr("Return was called when bookmarks contained only one value (perhaps visit hadn't been called or return was called multiple times)")
	change_page = true

func page_visit(_bookmark:String):
	vars._bookmarks.push_back(_bookmark)
	change_page = true

func get_relative_bookmark_index(from_key:String, offset:int) -> int:
	print("seeking ", from_key, " in ", bookmarks) 
	var index = bookmarks.find(from_key)
	if index == null:
		# We default to the title page.
		index = 0
	else:
		index = posmod(index + offset, bookmarks.size())
	return index

func get_relative_bookmark(from_key:String, offset:int) -> String:
	return bookmarks[get_relative_bookmark_index(from_key, offset)]

func save(quit_after_saving:bool = false):
	print("TODO: Save")
	has_unsaved_changes = false
	if quit_after_saving:
		Comic.quit()




