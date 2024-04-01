@tool
class_name ComicEditorPlugin
extends EditorPlugin

var edit_button:Button
var play_button:Button
var edit_mode:bool
var menu:PopupMenu
var pages:Dictionary

func _enter_tree():
	menu = PopupMenu.new()
	get_editor_interface().get_base_control().add_child(menu)
	menu.index_pressed.connect(item_pressed.bind(""))

	edit_button = ButtonAdvanced.new()
	edit_button.icon = preload("res://addons/icbm_editor/theme/icons/toolbar_button_edit.svg")
	edit_button.tooltip_text = "Open ICBM Editor\nOpen the ICBM Visual Editor."
	edit_button.focus_mode = Control.FOCUS_NONE
	edit_button.toggle_mode = false
	edit_button.modulate.b = 1.5
	edit_button.pressed.connect(open_menu.bind(true))
	edit_button.pressed_right.connect(run_last.bind(true))
	edit_button.flat = true
#	edit_button.add_theme_stylebox_override("", edit_button.get_theme_stylebox("Button"))
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, edit_button)

	play_button = ButtonAdvanced.new()
	play_button.icon = preload("res://addons/icbm_editor/theme/icons/toolbar_button_play.svg")
	play_button.tooltip_text = "Play from Page\nStart ICBM at the chosen page."
	play_button.focus_mode = Control.FOCUS_NONE
	play_button.toggle_mode = false
	play_button.modulate.b = 1.5
	play_button.pressed.connect(open_menu.bind(false))
	play_button.pressed_right.connect(run_last.bind(false))
	play_button.flat = true
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, play_button)

func _exit_tree():
	menu.queue_free()
	
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, edit_button)
	edit_button.queue_free()
	
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, play_button)
	play_button.queue_free()

func open_menu(edit_mode:bool):
	self.edit_mode = edit_mode

	# Ensure that the basic content files and directories exist
	var dir:DirAccess = DirAccess.open("res://")
	assert(dir != null)
	#if not dir.dir_exists("story"):
		#assert(dir.make_dir("story") == OK)
	if not dir.dir_exists("story/start"):
		assert(dir.make_dir_recursive("story/start") == OK)
	if not dir.dir_exists("images/start"):
		assert(dir.make_dir_recursive("images/start") == OK)
	if not FileAccess.file_exists(str(Comic.DIR_STORY, "start/_.txt")):
		var file:FileAccess = FileAccess.open(str(Comic.DIR_STORY, "start/_.txt"), FileAccess.WRITE)
		file.store_var([])
		file.close()


	var editor_theme:Theme = get_editor_interface().get_editor_theme()
#	print(editor_theme.get_icon_type_list())
#	print(editor_theme.get_icon_list("EditorIcons"))
	var icon_add = editor_theme.get_icon("Add", "EditorIcons")
	var icon_page = editor_theme.get_icon("File", "EditorIcons")
	var button:Button = edit_button if edit_mode else play_button
	menu.clear(true)
	pages = {"start":["_"]} # We begin with start in the dictionary, so that it will be at index 0.
	for chapter in DirAccess.get_directories_at(Comic.DIR_STORY):
		if chapter != "start":
			pages[chapter] = ["_"]
		for page in DirAccess.get_files_at(str(Comic.DIR_STORY, chapter)):
			if page.get_extension() == "txt" and page.get_basename().get_file() != "_":
				pages[chapter].push_back(page.get_basename().get_file())
	for chapter in pages.keys():
		menu.add_submenu_item(chapter, chapter)
		var submenu = PopupMenu.new()
		menu.add_child(submenu)
		submenu.name = chapter
		submenu.index_pressed.connect(item_pressed.bind(chapter))
		submenu.add_icon_item(icon_page, "Title Page")
		for page in pages[chapter]:
			print("Submenu page: ", page)
			if page != "_": # We've already added the title page.
				submenu.add_icon_item(icon_page, page)
		if edit_mode:
			submenu.add_icon_item(icon_add, "New Page")
	if edit_mode:
		menu.add_icon_item(icon_add, "New Chapter")
	menu.position = get_window().position + Vector2i(button.global_position.x + button.size.x - menu.size.x, button.global_position.y + button.size.y)

	menu.show()

func run():
	var bookmark:String = ComicEditor.load_settings().get("bookmark", "start")
	var file_path = str(Comic.DIR_STORY, bookmark if bookmark.contains("/") else str(bookmark, "/_"), ".txt")
	# Ensure that the file exists, and contains the page
	if FileAccess.file_exists(file_path):
		EditorInterface.play_custom_scene("res://addons/icbm_editor/editor.tscn" if edit_mode else "res://base/ICBM.tscn")
	#if failed, play unhappy thunk

func run_last(edit_mode:bool):
	self.edit_mode = edit_mode
	var editor_settings:Dictionary = ComicEditor.load_settings()
	editor_settings.bookmark = editor_settings.get("last_bookmark", "start")
	ComicEditor.save_settings(editor_settings)
	run()

func item_pressed(index:int, chapter:String = ""):
	var bookmark:String
	if chapter == "":
		# ADD CHAPTER
		# Find an unused chapter name
		var i = 1
		while pages.keys().has(str("chapter_", i)):
			i += 1
		bookmark = str("chapter_", i)
		var file:FileAccess = FileAccess.open(str(Comic.DIR_STORY, bookmark, "/_.txt"), FileAccess.WRITE)
		file.store_var([])
		file.close()
	elif index == pages[chapter].size():
		# ADD PAGE
		# Find an unused page name
		var i = 1
		while pages[chapter].has(str("page_", i)):
			i += 1
		bookmark = str(chapter, "/page_", i)
		var file:FileAccess = FileAccess.open(str(Comic.DIR_STORY, bookmark, ".txt"), FileAccess.WRITE)
		file.store_var([])
		file.close()
	else:
		# EDIT PAGE
		var page:String = pages[chapter][index]
		bookmark = chapter if page == "_" else str(chapter, "/", page)
	var editor_settings:Dictionary = ComicEditor.load_settings()
	editor_settings.last_bookmark = bookmark
	editor_settings.bookmark = bookmark
	ComicEditor.save_settings(editor_settings)
	run()

