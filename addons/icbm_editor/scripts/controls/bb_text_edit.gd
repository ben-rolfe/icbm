class_name BBTextEdit
extends TextEdit

var text_before_focus:String

func _gui_input(event):
	if event is InputEventKey and event.pressed and event.is_command_or_control_pressed ( ) and not event.shift_pressed:
		var selected_text:String = get_selected_text()
		if selected_text != "":
			match event.keycode:
				KEY_B:
					insert_text_at_caret(str("[b]", get_selected_text(), "[/b]"))
				KEY_I:
					insert_text_at_caret(str("[i]", get_selected_text(), "[/i]"))

