@tool
class_name ComicEditorPlugin
extends EditorPlugin

var edit_button:Button
var play_button:Button
var edit_mode:bool
var menu:PopupMenu
var pages:Dictionary
var config:ConfigFile = ConfigFile.new()


func _enter_tree():
	if not DirAccess.dir_exists_absolute(Comic.DIR_STORY):
		DirAccess.make_dir_absolute(Comic.DIR_STORY)
	if not DirAccess.dir_exists_absolute(Comic.DIR_IMAGES):
		DirAccess.make_dir_absolute(Comic.DIR_IMAGES)

	# Update all story/*.txt files to .dat files.
	#TODO: Remove this in August 2024
	for file in DirAccess.get_files_at(Comic.DIR_STORY):
		if file.get_extension() == "txt":
			DirAccess.rename_absolute(str(Comic.DIR_STORY, file), str(Comic.DIR_STORY, file.left(-3), Comic.STORY_EXT))
	for dir in DirAccess.get_directories_at(Comic.DIR_STORY):
		for file in DirAccess.get_files_at(str(Comic.DIR_STORY, dir)):
			if file.get_extension() == "txt":
				DirAccess.rename_absolute(str(Comic.DIR_STORY, dir, "/", file), str(Comic.DIR_STORY, dir, "/", file.left(-3), Comic.STORY_EXT))

	config.load(Comic.CONFIG_FILE)
	menu = PopupMenu.new()
	get_editor_interface().get_base_control().add_child(menu)
	menu.index_pressed.connect(item_pressed.bind(""))

	edit_button = ButtonAdvanced.new()
	edit_button.icon = load(str(ComicEditor.DIR_ICONS, "toolbar_button_edit.svg"))
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
	play_button.icon = load(str(ComicEditor.DIR_ICONS, "toolbar_button_play.svg"))
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
	ComicEditor.create_start_chapter()

	var editor_theme:Theme = get_editor_interface().get_editor_theme()
#	print(editor_theme.get_icon_type_list())
#	print(editor_theme.get_icon_list("EditorIcons"))
	var icon_add = editor_theme.get_icon("Add", "EditorIcons")
	var icon_page = editor_theme.get_icon("File", "EditorIcons")
	var button:Button = edit_button if edit_mode else play_button
	menu.clear(true)
	pages = {"start":["_"]} # We begin with start in the dictionary, so that it will be at index 0.
	for chapter in natural_sort(DirAccess.get_directories_at(Comic.DIR_STORY)):
		if chapter != "start":
			pages[chapter] = ["_"]
		for page in natural_sort(DirAccess.get_files_at(str(Comic.DIR_STORY, chapter))):
			if page.get_extension() == Comic.STORY_EXT and page.get_basename().get_file() != "_":
				pages[chapter].push_back(page.get_basename().get_file())
	for chapter in pages.keys():
		menu.add_submenu_item(chapter, chapter)
		var submenu = PopupMenu.new()
		menu.add_child(submenu)
		submenu.name = chapter
		submenu.index_pressed.connect(item_pressed.bind(chapter))
		submenu.add_icon_item(icon_page, "Title Page")
		for page in pages[chapter]:
			#print("Submenu page: ", page)
			if page != "_": # We've already added the title page.
				submenu.add_icon_item(icon_page, page)
		if edit_mode:
			submenu.add_icon_item(icon_add, "New Page")
	if edit_mode:
		menu.add_icon_item(icon_add, "New Chapter")
	menu.position = get_window().position + Vector2i(button.global_position.x + button.size.x - menu.size.x, button.global_position.y + button.size.y)

	menu.show()

func run():
	var bookmark:String = config.get_value("editor", "bookmark", "start")
	var file_path = str(Comic.DIR_STORY, bookmark if bookmark.contains("/") else str(bookmark, "/_"), ".", Comic.STORY_EXT)
	# Ensure that the file exists, and contains the page
	if FileAccess.file_exists(file_path):
		EditorInterface.play_custom_scene("res://addons/icbm_editor/editor.tscn" if edit_mode else "res://base/ICBM.tscn")
	#if failed, play unhappy thunk

func run_last(_edit_mode:bool):
	edit_mode = _edit_mode
	config.load(Comic.CONFIG_FILE)
	config.set_value("editor", "bookmark", config.get_value("editor", "last_bookmark", "start"))
	config.save(Comic.CONFIG_FILE)
	run()

func item_pressed(index:int, chapter:String = ""):
	var bookmark:String
	if chapter == "":
		# ADD CHAPTER
		# Find an unused chapter name
		bookmark = ComicEditor.get_unique_bookmark("chapter_1")
		DirAccess.make_dir_absolute(str(Comic.DIR_STORY, bookmark))
		var file:FileAccess = FileAccess.open(str(Comic.DIR_STORY, bookmark, "/_.", Comic.STORY_EXT), FileAccess.WRITE)
		file.store_var({})
		file.close()
	elif index == pages[chapter].size():
		# ADD PAGE
		# Find an unused page name
		bookmark = ComicEditor.get_unique_bookmark(str(chapter, "/page_1"))
		var file:FileAccess = FileAccess.open(str(Comic.DIR_STORY, bookmark, ".", Comic.STORY_EXT), FileAccess.WRITE)
		file.store_var({})
		file.close()
	else:
		# EDIT PAGE
		var page:String = pages[chapter][index]
		bookmark = chapter if page == "_" else str(chapter, "/", page)
	config.load(Comic.CONFIG_FILE)
	config.set_value("editor", "bookmark", bookmark)
	config.set_value("editor", "last_bookmark", bookmark)
	config.save(Comic.CONFIG_FILE)
	run()

# This is a duplicate of the natural_sort function in Comic - but we can't call that from this @tool class
func natural_sort(array:Array) -> Array:
	array.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	return array
