# Singleton name is Scribble
extends CanvasLayer

const EXT:String = "webp"
const DEV_EXT:String = "dev"
const CONFIG_FILE = "res://modules/scribble/config.cfg"

var scribble_menu:ScribbleMenu
var scribble_rect:ScribbleRect
var editor_only:bool = true
var unchanged:bool = true
var needs_save:bool = false
var config:ConfigFile = ConfigFile.new()

func _init():
	config.load(CONFIG_FILE)
	assert(Comic, "Comic must be autoloaded before Scribble")
	layer = 1
	Comic.editor_deleted.connect(_on_editor_deleted)
	Comic.editor_renamed.connect(_on_editor_renamed)
	Comic.editor_saved.connect(_on_editor_saved)
	Comic.page_changed.connect(_on_page_changed)
	Comic.quitted.connect(_on_quitted)

func _ready():
	Comic.add_editor_menu_item(3, "Scribble", str("res://modules/scribble/icons/scribble.svg"), open)
	scribble_rect = ScribbleRect.new()
	if Comic.book is ComicEditor:
		scribble_menu = ScribbleMenu.new()
		add_child(scribble_menu)
		close()
	add_child(scribble_rect)

func open():
	unchanged = true
	scribble_rect.active = true
	scribble_menu.open()

func save():
	close()

func cancel():
	close()

func close():
	scribble_rect.active = false
	scribble_menu.hide()

func _on_editor_deleted(bookmark:String):
	bookmark = _to_scribble_bookmark(bookmark)
	var dir:DirAccess = DirAccess.open(Comic.DIR_STORY)
	if dir.file_exists(str(bookmark, ".", EXT)):
		dir.remove(str(bookmark, ".", EXT))
		dir.remove(str(bookmark, ".", EXT, ".import"))
	if dir.file_exists(str(bookmark, ".", DEV_EXT)):
		dir.remove(str(bookmark, ".", DEV_EXT))
		#NOTE: The dev file format won't be imported by godot (that's the whole point of using it) so we don't have a .import to delete.

func _on_editor_renamed(old_bookmark:String, new_bookmark:String):
	old_bookmark = _to_scribble_bookmark(old_bookmark)
	new_bookmark = _to_scribble_bookmark(new_bookmark)
	var dir:DirAccess = DirAccess.open(Comic.DIR_STORY)
	if dir.file_exists(str(old_bookmark, ".", EXT)):
		dir.copy(str(old_bookmark, ".", EXT), str(new_bookmark, ".", EXT))
		#NOTE: We don't copy the .import file (maybe we should??) - instead, we let godot reimport the file in its new location.
		dir.remove(str(old_bookmark, ".", EXT))
		dir.remove(str(old_bookmark, ".", EXT, ".import"))
	if dir.file_exists(str(old_bookmark, ".", DEV_EXT)):
		dir.copy(str(old_bookmark, ".", DEV_EXT), str(new_bookmark, ".", DEV_EXT))
		dir.remove(str(old_bookmark, ".", DEV_EXT))

func _on_editor_saved(bookmark:String):
	if needs_save:
		# First, delete any current scribble.
		_on_editor_deleted(bookmark)
		# Now, determine if there's any data in the scribble.
		needs_save = false
		var data:PackedByteArray = scribble_rect.image.get_data()
		for i in range(3, data.size(), 4): # We only need to check the alpha pixels - if they're all 0, we have no image.
			if data[i] > 0:
				needs_save = true
				break
		if needs_save:
			bookmark = _to_scribble_bookmark(bookmark)
			if editor_only:
				var file:FileAccess = FileAccess.open(str(Comic.DIR_STORY, bookmark, ".", DEV_EXT), FileAccess.WRITE)
				file.store_var(scribble_rect.image.save_webp_to_buffer())
				file.close()
			else:
				scribble_rect.image.save_webp(str(Comic.DIR_STORY, bookmark, ".", EXT))
	needs_save = false

func _to_scribble_bookmark(bookmark:String) -> String:
	if bookmark.contains("/"):
		bookmark = bookmark.replace("/", "/_scribble_")
	else:
		bookmark = str(bookmark, "/_scribble__")
	return bookmark
	
func _on_page_changed(bookmark:String):
	bookmark = _to_scribble_bookmark(bookmark)
	if FileAccess.file_exists(str(Comic.DIR_STORY, bookmark, ".", EXT)):
		editor_only = false
		var texture:Texture2D = load(str(Comic.DIR_STORY, bookmark, ".", EXT))
		scribble_rect.image = texture.get_image()
		scribble_rect.apply_image()
	else:
		editor_only = true
		if Comic.book is ComicEditor and FileAccess.file_exists(str(Comic.DIR_STORY, bookmark, ".", DEV_EXT)):
			var file:FileAccess = FileAccess.open(str(Comic.DIR_STORY, bookmark, ".", DEV_EXT), FileAccess.READ)
			scribble_rect.image.load_webp_from_buffer(file.get_var())
			file.close()
			scribble_rect.apply_image()
		else:
			scribble_rect.clear_image()

func _on_quitted():
	config.save(CONFIG_FILE)
