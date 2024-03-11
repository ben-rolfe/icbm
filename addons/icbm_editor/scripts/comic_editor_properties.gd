class_name ComicEditorProperties
extends VBoxContainer

const MARGIN:int = 21

func prepare():
	if Comic.book.selected_element != null and Comic.book.selected_element.position.x > Comic.size.x / 2:
		# Box to left
		get_parent().get_parent().position.x = MARGIN
	else:
		# Box to right
		get_parent().get_parent().position.x = Comic.size.x - get_parent().get_parent().size.x - MARGIN
