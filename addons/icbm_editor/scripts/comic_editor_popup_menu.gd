class_name ComicEditorPopupMenu
extends PopupMenu

func _input(event:InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		hide()
