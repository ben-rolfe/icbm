class_name ComicWidgetLayer
extends ComicLayer

func clear():
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _draw():
	# Hotspots draw on the widget layer
	for o in Comic.book.page.os:
		if Comic.book.page.os[o] is ComicHotspot and Comic.book.page.os[o].get_parent() != null:
			Comic.book.page.os[o].draw_shape(self)

	# The selected element itself (not its widgets) may also want to draw onto this layer
	if Comic.book.selected_element != null:
		var selected_widget_parent:Object = Comic.book.selected_element
		while selected_widget_parent is ComicWidget:
			selected_widget_parent = selected_widget_parent.serves
		if selected_widget_parent.has_method("draw_widgets"):
			selected_widget_parent.draw_widgets(self)

	for widget in get_children():
		if widget is ComicWidget:
			widget.reposition()
	for widget in get_children():
		if widget is ComicWidget:
			widget.draw(self)
