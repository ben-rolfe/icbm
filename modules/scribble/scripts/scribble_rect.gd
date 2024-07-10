class_name ScribbleRect
extends TextureRect

const STEP_DISTANCE:float = 1
const MAX_UNDO = 10

enum Tool { ERASER, PENCIL, }
var tool:Tool:
	get:
		return Scribble.config.get_value("scribble", "tool", Tool.PENCIL)
	set(value):
		Scribble.config.set_value("scribble", "tool", value)

var image:Image

var pencil:Image = Image.create(100,100, false, Image.FORMAT_RGBA8)
var pencil_rect:Rect2i
var pencil_offset:Vector2
var pencil_color:Color:
	get:
		return Scribble.config.get_value("scribble", "pencil_color", Color.WHITE)
	set(value):
		Scribble.config.set_value("scribble", "pencil_color", value)
		apply_pencil_properties()
var pencil_size:int:
	get:
		return Scribble.config.get_value("scribble", "pencil_size", 4)
	set(value):
		Scribble.config.set_value("scribble", "pencil_size", value)
		apply_pencil_properties()

var eraser:Image = Image.create(100,100, false, Image.FORMAT_RGBA8)
var eraser_mask:Image = Image.create(100,100, false, Image.FORMAT_RGBA8)
var eraser_rect:Rect2i
var eraser_offset:Vector2
var eraser_size:int:
	get:
		return Scribble.config.get_value("scribble", "eraser_size", 16)
	set(value):
		Scribble.config.set_value("scribble", "eraser_size", value)
		apply_eraser_properties()

var last_pos:Vector2

var undo_steps:Array = []
var redo_steps:Array = []


var active:bool:
	get:
		return mouse_filter == Control.MOUSE_FILTER_STOP
	set(value):
		mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE
		if value:
			pass

func _init():
	clear_image()
	apply_pencil_properties()
	apply_eraser_properties()

func _input(event:InputEvent):
	if Comic.book is ComicEditor:
		if event is InputEventKey and event.pressed and active:
			if event.is_action_pressed("ui_cancel"):
				get_viewport().set_input_as_handled()
			elif event.is_action_pressed("ui_undo"):
				undo()
				get_viewport().set_input_as_handled()
			elif event.is_action_pressed("ui_redo"):
				redo()
				get_viewport().set_input_as_handled()
			else:
				# We're not handling it - pass it to the ComicEditor
				Comic.book._unhandled_key_input(event)

func _gui_input(event:InputEvent):
	if Comic.book is ComicEditor:
		if event is InputEventMouseMotion:
			if not is_zero_approx(event.pressure): 
				paint_to(event.position)
				last_pos = event.position
		elif event is InputEventMouseButton and event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					create_undo_step()
					last_pos = event.position
					paint_to(event.position)
				MOUSE_BUTTON_RIGHT:
					# On a right click, we close the scribble and manually pass the click event to the background.
					Scribble.close()
					Comic.book.page.background._gui_input(event)

func paint_to(next_pos:Vector2):
	var steps:int = floor(next_pos.distance_to(last_pos) / STEP_DISTANCE)
	var step_vector = Vector2.ZERO
	if steps == 0:
		steps = 1
	else:
		step_vector = (last_pos - next_pos) / steps
	for step in steps:
		match tool:
			Tool.PENCIL:
				#print("pencil")
				image.blend_rect(pencil, pencil_rect, next_pos + step * step_vector - pencil_offset)
			Tool.ERASER:
				#print("eraser")
				image.blit_rect_mask(eraser, eraser_mask, eraser_rect, next_pos + step * step_vector - eraser_offset)
	apply_image()

func clear_image():
	#NOTE: This doesn't automatically generate an undo step, as we call it on init.
	image = Image.create(int(Comic.size.x), int(Comic.size.y), false, Image.FORMAT_RGBA8)
	apply_image()

func apply_image():
	texture = ImageTexture.create_from_image(image)

func create_undo_step():
	Scribble.unchanged = false
	Scribble.needs_save = true
	redo_steps = []
	var undo_image = Image.new()
	undo_image.copy_from(image)
	undo_steps.push_back(undo_image)
	if undo_steps.size() > MAX_UNDO:
		undo_steps.pop_front()

func undo():
	print("UNDO SCRIB")
	if undo_steps.size() > 0:
		redo_steps.push_back(image)
		image = undo_steps.pop_back()
		apply_image()

func redo():
	if redo_steps.size() > 0:
		undo_steps.push_back(image)
		image = redo_steps.pop_back()
		apply_image()
		
func apply_pencil_properties():
	#print(pencil_size, " -> ", pencil_color)
	var pencil_texture:Texture2D = load("res://modules/scribble/brushes/round.png")
	pencil = pencil_texture.get_image()
	pencil.resize(pencil_size, pencil_size)
	pencil_rect = Rect2i(0,0,pencil_size,pencil_size)
	pencil_offset = Vector2.ONE * (pencil_size * 0.5)
	
	# recolor the pencil
	var alpha_data:PackedByteArray = pencil.get_data()
	pencil.fill(pencil_color)
	var data:PackedByteArray = pencil.get_data()
	for i in range(3, data.size(), 4):
		data[i] = alpha_data[i]
	pencil.set_data(pencil_size, pencil_size, false, Image.FORMAT_RGBA8, data)

func apply_eraser_properties():
	eraser = Image.create(eraser_size, eraser_size, false, Image.FORMAT_RGBA8)
	var eraser_texture:Texture2D = load("res://modules/scribble/brushes/round.png")
	eraser_mask = eraser_texture.get_image()
	eraser_mask.resize(eraser_size, eraser_size)
	eraser_rect = Rect2i(0, 0, eraser_size, eraser_size)
	eraser_offset = Vector2.ONE * (eraser_size * 0.5)

