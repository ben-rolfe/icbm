class_name ButtonAdvanced
extends Button

signal pressed_right

func _gui_input(event:InputEvent):
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and is_hovered():
		pressed_right.emit()
