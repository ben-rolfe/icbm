class_name ComicBackground
extends TextureRect

func _init():
	name = "background"
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event:InputEvent):
	#TODO: Fix
	if event is InputEventMouseButton and event.pressed and get_rect().has_point(event.global_position):
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_double_click():
				Comic.book.double_clicked(self, event)
			else:
				Comic.book.left_clicked(self, event)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			Comic.book.right_clicked(self, event)

func rebuild():
	# Setting null seems necessary to change the bg after updating the file.
	texture = null
	texture = Comic.load_texture(str(Comic.book.page.bookmark, "" if Comic.book.page.bookmark.contains("/") else "/_"))
	if texture == null:
		if ResourceLoader.exists(Comic.DEFAULT_BG):
			print("Background image not found - using default background")
			texture = ResourceLoader.load(Comic.DEFAULT_BG)
		else:
			printerr("Background image not found and no default background found. Giving up.")

