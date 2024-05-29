class_name ComicBackground
extends TextureRect

func _init():
	name = "background"
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event:InputEvent):
	if event is InputEventMouseButton and event.pressed:
		var o:CanvasItem = self if Comic.book.page.hovered_hotspots.size() == 0 else Comic.book.page.hovered_hotspots[-1]
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_double_click() and Comic.book.has_method("double_clicked"):
				Comic.book.double_clicked(o, event)
			elif Comic.book.has_method("left_clicked"): #NOTE: if the above has_method("double_clicked") returns false, we fall through to this elif, so a double-click will be treated as a click
				Comic.book.left_clicked(o, event)
		elif event.button_index == MOUSE_BUTTON_RIGHT and Comic.book.has_method("right_clicked"):
			Comic.book.right_clicked(o, event)

func rebuild():
	# Setting null seems necessary to change the bg after updating the file.
	texture = null
	texture = Comic.load_texture(str(Comic.book.page.bookmark, "" if Comic.book.page.bookmark.contains("/") else "/_"))
	if texture == null:
		# No background - use black background instead.
		texture = ImageTexture.create_from_image(Image.create(int(Comic.size.x), int(Comic.size.y), false, Image.FORMAT_RGB8))
		#if ResourceLoader.exists(Comic.DEFAULT_BG):
			#print("Background image not found - using default background")
			#texture = ResourceLoader.load(Comic.DEFAULT_BG)
		#else:
			#printerr("Background image not found and no default background found. Giving up.")

