class_name ComicEditorBookProperties
extends ComicEditorProperties

@export var auto_save_slot_check_box:CheckBox
@export var manual_save_slots_check_box:CheckBox
@export var init_commands_text_edit:TextEdit
var init_commands_before_changes:String

func _ready():
	auto_save_slot_check_box.toggled.connect(_on_auto_save_slot_check_box_toggled)
	manual_save_slots_check_box.toggled.connect(_on_manual_save_slots_check_box_toggled)

	init_commands_text_edit.text_changed.connect(_on_init_commands_text_edit_changed)	
	init_commands_text_edit.caret_blink = true
	init_commands_text_edit.focus_entered.connect(_on_init_commands_text_edit_focused)
	init_commands_text_edit.focus_exited.connect(_on_init_commands_text_edit_unfocused)

func prepare():
	super()
	print(Comic.book._data)
	auto_save_slot_check_box.button_pressed = Comic.book.auto_save_slot
	manual_save_slots_check_box.button_pressed = Comic.book.manual_save_slots
	init_commands_text_edit.text = Comic.book.init_commands

func _on_auto_save_slot_check_box_toggled(toggled_on:bool):
	Comic.book.auto_save_slot = toggled_on

func _on_manual_save_slots_check_box_toggled(toggled_on:bool):
	Comic.book.manual_save_slots = toggled_on

func _on_init_commands_text_edit_changed():
	Comic.book.init_commands = ComicEditor.unparse_text_edit(init_commands_text_edit.text)

func _on_init_commands_text_edit_focused():
	init_commands_before_changes = init_commands_text_edit.text
	
func _on_init_commands_text_edit_unfocused():
	if init_commands_text_edit.text != init_commands_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(Comic.book)
		reversion.data.init_commands = ComicEditor.unparse_text_edit(init_commands_before_changes)
		Comic.book.add_undo_step([reversion])
