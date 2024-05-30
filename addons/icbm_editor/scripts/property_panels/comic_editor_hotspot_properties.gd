class_name ComicEditorHotspotProperties
extends ComicEditorProperties

@export var action_button:OptionButton
@export var action_target_button:OptionButton
@export var action_commands_textedit:TextEdit
@export var change_cursor_checkbox:CheckBox

var hotspot:ComicEditorHotspot
var commands_before_changes:String

func _ready():
	for action in ComicButton.Action:
		action_button.add_item(action.capitalize(), ComicButton.Action[action])
	action_button.item_selected.connect(_on_action_item_selected)
	for bookmark in Comic.book.bookmarks:
		action_target_button.add_item(bookmark)
	action_target_button.item_selected.connect(_on_action_target_item_selected)

	action_commands_textedit.text_changed.connect(_on_commands_textedit_changed)	
	action_commands_textedit.caret_blink = true
	action_commands_textedit.focus_entered.connect(_on_commands_textedit_focused)
	action_commands_textedit.focus_exited.connect(_on_commands_textedit_unfocused)

	change_cursor_checkbox.toggled.connect(_on_change_cursor_checkbox_toggled)


func prepare():
	super()
	hotspot = Comic.book.selected_element

	action_button.select(hotspot.action)
	after_action_changed()
	
	change_cursor_checkbox.button_pressed = hotspot.change_cursor

func after_action_changed():
	match hotspot.action:
		ComicButton.Action.GO, ComicButton.Action.VISIT:
			action_commands_textedit.hide()
			action_target_button.show()
			hotspot.action_commands = ""
			# If bookmark is blank, default to the next page, otherwise, set it.
			var index:int = Comic.book.get_relative_bookmark_index(Comic.book.page.bookmark, 1) if hotspot.action_bookmark == "" else Comic.book.bookmarks.find(hotspot.action_bookmark)
			action_target_button.select(index)
			hotspot.action_bookmark = Comic.book.bookmarks[index]
		ComicButton.Action.PARSE_COMMANDS:
			action_target_button.hide()
			action_commands_textedit.show()
			hotspot.action_bookmark = ""
			action_commands_textedit.text = hotspot.action_commands
		_:
			action_target_button.hide()
			action_commands_textedit.hide()
			hotspot.action_bookmark = ""
			hotspot.action_commands = ""

func _on_commands_textedit_changed():
	hotspot.action_commands = ComicEditor.unparse_text_edit(action_commands_textedit.text)
	hotspot.rebuild(true)

func _on_commands_textedit_focused():
	commands_before_changes = action_commands_textedit.text
	
func _on_commands_textedit_unfocused():
	if action_commands_textedit.text != commands_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(hotspot)
		reversion.data.action_commands = ComicEditor.unparse_text_edit(commands_before_changes)
		Comic.book.add_undo_step([reversion])

func _on_action_item_selected(index:int):
	if hotspot.action != index:
		Comic.book.add_undo_step([ComicReversionData.new(hotspot)])
		hotspot.action = index
		hotspot.rebuild(true)
		after_action_changed()

func _on_action_target_item_selected(index:int):
	Comic.book.add_undo_step([ComicReversionData.new(hotspot)])
	hotspot.action_bookmark = Comic.book.bookmarks[index]
	hotspot.rebuild(true)

func _on_change_cursor_checkbox_toggled(toggled_on:bool):
	hotspot.change_cursor = toggled_on
	hotspot.rebuild(true)

