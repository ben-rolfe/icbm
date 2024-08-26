class_name ComicEditorButtonProperties
extends ComicEditorProperties

@export var text_edit:LineEdit
@export var action_button:OptionButton
@export var action_target_button:OptionButton
@export var action_commands_textedit:TextEdit
@export var enabled_text_edit:TextEdit

var button:ComicEditorButton
var text_before_changes:String
var commands_before_changes:String
var enabled_before_changes:String


@export var shown_check_box:CheckBox
@export var appear_spin_box:SpinBox
@export var appear_button:OptionButton
@export var disappear_spin_box:SpinBox
@export var disappear_button:OptionButton

func _ready():
	text_edit.text_changed.connect(_on_text_changed)
	text_edit.caret_blink = true
	text_edit.focus_entered.connect(_on_text_focused)
	text_edit.focus_exited.connect(_on_text_unfocused)
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

	enabled_text_edit.text_changed.connect(_on_enabled_text_edit_changed)
	enabled_text_edit.caret_blink = true
	enabled_text_edit.focus_entered.connect(_on_enabled_text_edit_focused)
	enabled_text_edit.focus_exited.connect(_on_enabled_text_edit_unfocused)

	shown_check_box.toggled.connect(_on_shown_check_box_toggled)
	for i in Comic.DELAY_TYPES.size():
		appear_button.add_item(Comic.DELAY_TYPES[i])
		appear_button.set_item_metadata(-1, i)
		disappear_button.add_item(Comic.DELAY_TYPES[i])
		disappear_button.set_item_metadata(-1, i)
	appear_button.item_selected.connect(_on_appear_button_item_selected)
	appear_spin_box.value_changed.connect(_on_appear_spin_box_value_changed)
	disappear_button.item_selected.connect(_on_disappear_button_item_selected)
	disappear_spin_box.value_changed.connect(_on_disappear_spin_box_value_changed)


func prepare():
	# We don't call super - button properties is always on the left
	get_parent().get_parent().position.x = MARGIN
	button = Comic.book.selected_element

	action_button.select(button.action)
	after_action_changed()

	text_edit.text = ComicEditor.parse_text_edit(button.content)
	text_edit.grab_focus()
	if text_edit.text == Comic.default_presets.button[""].content:
		text_edit.select_all()
	else:
		text_edit.caret_column = text_edit.text.length()

	enabled_text_edit.text = button.enabled_test

	shown_check_box.button_pressed = button.shown
	appear_spin_box.value = button.appear
	appear_button.select(button.appear_type)
	if button.appear_type == 0:
		appear_spin_box.hide()
	else:
		appear_spin_box.show()
		
	disappear_spin_box.value = button.disappear
	disappear_button.select(button.disappear_type)
	if button.disappear_type == 0:
		disappear_spin_box.hide()
	else:
		disappear_spin_box.show()

func after_action_changed():
	match button.action:
		ComicButton.Action.GO, ComicButton.Action.VISIT:
			action_commands_textedit.hide()
			action_target_button.show()
			button.action_commands = ""
			# If bookmark is blank, default to the next page, otherwise, set it.
			var index:int = Comic.book.get_relative_bookmark_index(Comic.book.page.bookmark, 1) if button.action_bookmark == "" else Comic.book.bookmarks.find(button.action_bookmark)
			action_target_button.select(index)
			button.action_bookmark = Comic.book.bookmarks[index]
		ComicButton.Action.PARSE_COMMANDS:
			action_target_button.hide()
			action_commands_textedit.show()
			button.action_bookmark = ""
			action_commands_textedit.text = button.action_commands
		_:
			action_target_button.hide()
			action_commands_textedit.hide()
			button.action_bookmark = ""
			button.action_commands = ""

func _on_text_changed(new_text:String):
	button.content = ComicEditor.unparse_text_edit(text_edit.text)
	button.rebuild(true)

func _on_text_focused():
	text_before_changes = text_edit.text
	
func _on_text_unfocused():
	if text_edit.text != text_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(button)
		reversion.data.text = ComicEditor.unparse_text_edit(text_before_changes)
		Comic.book.add_undo_step([reversion])

func _on_commands_textedit_changed():
	button.action_commands = ComicEditor.unparse_text_edit(action_commands_textedit.text)
	button.rebuild(true)

func _on_commands_textedit_focused():
	commands_before_changes = action_commands_textedit.text
	
func _on_commands_textedit_unfocused():
	if action_commands_textedit.text != commands_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(button)
		reversion.data.action_commands = ComicEditor.unparse_text_edit(commands_before_changes)
		Comic.book.add_undo_step([reversion])

func _on_enabled_text_edit_changed():
	button.enabled_test = ComicEditor.unparse_text_edit(enabled_text_edit.text)
	button.rebuild(true)

func _on_enabled_text_edit_focused():
	enabled_before_changes = enabled_text_edit.text
	
func _on_enabled_text_edit_unfocused():
	if enabled_text_edit.text != enabled_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(button)
		reversion.data.enabled_test = ComicEditor.unparse_text_edit(enabled_before_changes)
		Comic.book.add_undo_step([reversion])

func _on_action_item_selected(index:int):
	if button.action != index:
		Comic.book.add_undo_step([ComicReversionData.new(button)])
		button.action = index
		button.rebuild(true)
		after_action_changed()

func _on_action_target_item_selected(index:int):
	Comic.book.add_undo_step([ComicReversionData.new(button)])
	button.action_bookmark = Comic.book.bookmarks[index]
	button.rebuild(true)

func _on_shown_check_box_toggled(toggled_on:bool):
	Comic.book.add_undo_step([ComicReversionData.new(button)])
	button.shown = toggled_on

func _on_appear_button_item_selected(index:int):
	if index == 0:
		# We don't have an undo step here, because the next line will trigger one
		appear_spin_box.value = 0
		appear_spin_box.hide()
	else:
		Comic.book.add_undo_step([ComicReversionData.new(button)])
		appear_spin_box.show()
	button.appear_type = appear_button.get_item_metadata(index)

func _on_disappear_button_item_selected(index:int):
	if index == 0:
		# We don't have an undo step here, because the next line will trigger one
		disappear_spin_box.value = 0
		disappear_spin_box.hide()
	else:
		Comic.book.add_undo_step([ComicReversionData.new(button)])
		disappear_spin_box.show()
	button.disappear_type = disappear_button.get_item_metadata(index)
		
func _on_appear_spin_box_value_changed(value:int):
	Comic.book.add_undo_step([ComicReversionData.new(button)])
	button.appear = value

func _on_disappear_spin_box_value_changed(value:int):
	Comic.book.add_undo_step([ComicReversionData.new(button)])
	button.disappear = value
	
