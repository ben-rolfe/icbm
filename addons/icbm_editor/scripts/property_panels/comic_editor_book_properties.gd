class_name ComicEditorBookProperties
extends ComicEditorProperties

@export var auto_save_slot_check_box:CheckBox
@export var manual_save_slots_check_box:CheckBox

func _ready():
	auto_save_slot_check_box.toggled.connect(_on_auto_save_slot_check_box_toggled)
	manual_save_slots_check_box.toggled.connect(_on_manual_save_slots_check_box_toggled)

func prepare():
	super()
	print(Comic.book._data)
	auto_save_slot_check_box.button_pressed = Comic.book.auto_save_slot
	manual_save_slots_check_box.button_pressed = Comic.book.manual_save_slots

func _on_auto_save_slot_check_box_toggled(toggled_on:bool):
	Comic.book.auto_save_slot = toggled_on

func _on_manual_save_slots_check_box_toggled(toggled_on:bool):
	Comic.book.manual_save_slots = toggled_on
