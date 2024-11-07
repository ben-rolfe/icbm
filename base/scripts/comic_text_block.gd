class_name ComicTextBlock
extends RichTextLabel

func _init():
	theme = preload("res://theme/default.tres")
	scroll_active = false
	fit_content = true
	add_theme_stylebox_override("normal", theme.get_stylebox("normal", "ComicTextBlock"))
	add_theme_color_override("default_color", theme.get_color("default_color", "ComicTextBlock"))
