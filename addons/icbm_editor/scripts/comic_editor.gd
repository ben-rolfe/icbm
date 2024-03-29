class_name ComicEditor
extends ComicBook

enum MenuCommand {
	# Add
	ADD_BALLOON,
	ADD_CAPTION,
	ADD_LINE,
	ADD_LABEL,

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

const SETTINGS_PATH:String = "user://editor_settings.cfg"
const DIR_ICONS:String = "res://addons/icbm_editor/theme/icons/"
const MAX_UNDO_STEPS:int = 50

var menu:PopupMenu
var popup_target:Control
var _page_keys:Array
var menu_action_position:Vector2
var _grabbed_element:Control
var _grab_offset:Vector2

var undo_steps:Array
var redo_steps:Array

var unique_ref_id = 0

@export var properties_panel:PanelContainer
@export var balloon_properties:ComicEditorBalloonProperties
@export var button_properties:ComicEditorButtonProperties
@export var label_properties:ComicEditorLabelProperties
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
	get_window().title = str("ICBM Visual Editor: ", vars._bookmarks[-1])

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
	menu.show()
	
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

func get_unique_ref() -> String:
	unique_ref_id += 1
	return str("_auto_", unique_ref_id)

func safety_check_unique_ref(ref:String):
	if ref.left(6) == "_auto_":
		ref = ref.substr(6)
		unique_ref_id = max(unique_ref_id, int(ref))

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
	#print("TODO: Save changes to ", bookmark)
	var file:FileAccess = FileAccess.open(str(Comic.DIR_STORY, bookmark if bookmark.contains("/") else str(bookmark, "/_"), ".txt"), FileAccess.WRITE)
	file.store_var(page.get_save_data())
	file.close()
	
	#var chapter:String = bookmark.split("/")[0] if bookmark.contains("/") else bookmark
	#var s:String
	#for data_bookmark in _page_data:
		#if data_bookmark.split("/")[0] == chapter:
			## The page is in this chapter, and needs to be saved in this file.
			#if data_bookmark == bookmark:
				## It's the page we're editing. Ignore the stored data and get the page to give us the new data.
				#s = str(s, page.get_save_string())
			#else:
				## It's not the page we're editing. Use the stored data
				#if data_bookmark.contains("/"):
					#s = str(s, data_bookmark.split("/")[1], "\n")
				#for line in _page_data[data_bookmark]:
					#s = str(s, "	", line, "\n")
			## Add a line between pages
			#s = str(s, "\n")
#
	#var file:FileAccess = FileAccess.open(str(Comic.DIR_STORY, chapter, ".txt"), FileAccess.WRITE)
	#file.store_string(s)
	#file.close()
	
	page.background.save()
	
	has_unsaved_changes = false
	if quit_after_saving:
		Comic.quit()

static func load_setting(key:String, default_value:Variant = null) -> Variant:
	return load_settings().get(key, default_value)

static func load_settings() -> Dictionary:
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		var r:Dictionary = file.get_var()
		file.close()
		return r
	return {}

static func save_setting(key:String, value:Variant):
	var settings = ComicEditor.load_settings()
	settings[key] = value
	ComicEditor.save_settings(settings)

static func save_settings(value:Dictionary):
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_var(value)
	file.close()


static func parse_text_edit(s:String) -> String:
	return s.replace("[br]", "\n").replace("[tab]","	")

static func unparse_text_edit(s:String) -> String:
	return s.replace("\n", "[br]").replace("	","[tab]")

