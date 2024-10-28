class_name ComicReversion
extends RefCounted

var o:Node
var focus_after:bool = true

func _init():
	Comic.book.has_unsaved_changes = true

func apply():
	Comic.book.has_unsaved_changes = true
	Comic.book.page.rebuild_lookups()
	if focus_after and o is CanvasItem and o.get_parent() != null:
		Comic.book.selected_element = o
