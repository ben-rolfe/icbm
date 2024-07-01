# Singleton name is Scribble
extends CanvasLayer

var texture_rect:TextureRect

func _init():
	assert(Comic, "Comic must be autoloaded before Scribble")

	layer = 1
	texture_rect = TextureRect.new()
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(texture_rect)
	
func _ready():
#	Comic.add_editor_menu_item(4, "Scribble", str("res://modules/scribble/icons/scribble.svg"), menu_scribble)

	texture_rect.texture = ImageTexture.create_from_image(Image.create(int(Comic.size.x), int(Comic.size.y), false, Image.FORMAT_RGBA8))

func edit():
	texture_rect.mouse_filter = Control.MOUSE_FILTER_STOP

func save():
	close()

func cancel():
	close()

func close():
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func menu_scribble():
	Scribble.edit()
