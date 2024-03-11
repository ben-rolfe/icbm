class_name ComicBook
extends Control

@export var page_container:SubViewportContainer
@export var buttons_container:BoxContainer
#@export var debug_bookmark:String = "start"

var aliases:Dictionary = {}
var _buttons:Array[ComicButton] = []
var change_page:bool
var default_balloon_layer:int
var history:Array = []
var _history_size:int
#var _page_data:Dictionary = {}
var vars:Dictionary
var page:ComicPage
var has_unsaved_changes:bool

# ------------------------------------------------------------------------------

var bookmark:String:
	get:
		return vars._bookmarks[-1]
	set(value):
		vars._bookmarks[-1] = value

# ------------------------------------------------------------------------------

func _init():
	Comic.book = self
	_history_size = Comic.theme.get_constant("history_size", "Settings")
	default_balloon_layer = Comic.theme.get_constant("default_layer", "Balloon")

func _ready():
#	read_story_directory()
	if OS.is_debug_build():
		var editor_settings:Dictionary = ComicEditor.load_settings()
		print("Starting '", editor_settings.bookmark, "'")
		start(editor_settings.get("bookmark", "start"))
		# We reset the bookmark to start, so that that will be open next time the game is run (unless changed by ComicEditorPlugin, in the meantime
		editor_settings.bookmark = "start"
		ComicEditor.save_settings(editor_settings)
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
				go_back()

func _process(delta:float):
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
		page.activate_bg_button()

func right_clicked(control:Control, _event:InputEvent):
	if control is ComicBackground:
		go_back()

func _show_page():
	change_page = false
	print("--- NEW PAGE ---")
	history.push_back(vars.duplicate(true))
	print(history)
	while history.size() > _history_size:
		history.pop_front()
#	assert( _page_data.has(bookmark), "Bookmark pointed to non-existent page '" + bookmark + "'.");
	while _buttons.size() > 0:
		_buttons.pop_back().queue_free()
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

func go_back():
	if history.size() > 1:
		history.pop_back() # This is the vars history for the *current* page - we discard it.
		vars = history.pop_back()	#behind it is the vars history for the previous page. We remove it and load it into vars - changing the page will add it back to the history.
		print("Go back!")
		print(history)
		change_page = true

func save(quit_after_saving:bool = false):
	print("TODO: Save")
	has_unsaved_changes = false
	if quit_after_saving:
		Comic.quit()


