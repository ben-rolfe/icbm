class_name ComicEditorImage
extends ComicImage

func _get_drag_data(at_position:Vector2):
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	Comic.book.grab(self, at_position - anchor)

func dropped(global_position:Vector2):
	dragged(global_position)
	
func dragged(global_position:Vector2):
	# convert position to units
	anchor = ComicEditor.snap(global_position)
	rebuild(true)

func has_point(point:Vector2) -> bool:
	return get_rect().has_point(point)

func draw_widgets(layer:ComicWidgetLayer):
	# Draw a box around the image
	layer.draw_polyline(PackedVector2Array([position, position + Vector2.RIGHT * size.x, position + size, position + Vector2.DOWN * size.y, position]), ComicEditorBalloon.WIDGET_COLOR, ComicWidget.THIN)
	
	# Draw a cross-hairs at the anchor
	layer.draw_line(anchor + Vector2.UP * ComicWidget.RADIUS, anchor + Vector2.DOWN * ComicWidget.RADIUS, ComicEditorBalloon.WIDGET_COLOR, ComicWidget.THICK)
	layer.draw_line(anchor + Vector2.LEFT * ComicWidget.RADIUS, anchor + Vector2.RIGHT * ComicWidget.RADIUS, ComicEditorBalloon.WIDGET_COLOR, ComicWidget.THICK)

func rebuild(_rebuild_subobjects:bool = false):
	super()
	Comic.book.page.redraw()

func remove():
	Comic.book.add_undo_step([ComicReversionParent.new(self, get_parent())])
	get_parent().remove_child(self)
	Comic.book.page.redraw(true)
	Comic.book.selected_element = null

func get_save_data() -> Dictionary:
	return _data.duplicate()

func bump(direction:Vector2):
	#TODO: Figure out a way to not save on multiple bumps
	Comic.book.add_undo_step([ComicReversionData.new(self)])
	anchor += direction * ComicEditor.snap_distance * ComicEditor.BUMP_AMOUNT
	rebuild(true)

func _on_key_pressed(event:InputEventKey):
	match event.keycode:
		KEY_UP:
			bump(Vector2.UP)
		KEY_DOWN:
			bump(Vector2.DOWN)
		KEY_LEFT:
			bump(Vector2.LEFT)
		KEY_RIGHT:
			bump(Vector2.RIGHT)
		KEY_DELETE:
			remove()
