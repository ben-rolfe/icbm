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
	var bg_bookmark = Comic.book.page.bookmark if Comic.book.page.bg_share == "" else Comic.book.page.bg_share
	var new_texture:Texture2D = Comic.load_texture(str(bg_bookmark, "" if bg_bookmark.contains("/") else "/_"), Comic.DIR_STORY, ResourceLoader.CACHE_MODE_REPLACE)
	if new_texture != null:
		texture = new_texture
	else:
		texture = null
		if Comic.book.page.bg_color == Color.BLACK:
			texture = ImageTexture.create_from_image(Image.create(int(Comic.size.x), int(Comic.size.y), false, Image.FORMAT_RGB8))
		else:
			var image = Image.create(int(Comic.size.x), int(Comic.size.y), false, Image.FORMAT_RGB8)
			image.fill(Comic.book.page.bg_color)
			texture = ImageTexture.create_from_image(image)
