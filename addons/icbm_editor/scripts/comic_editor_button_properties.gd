class_name ComicEditorButtonProperties
extends ComicEditorProperties


func prepare():
	# We don't call super - button properties is always on the left
	get_parent().get_parent().position.x = MARGIN
	
