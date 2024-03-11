class_name ComicReversion
extends RefCounted

var o:Control
var focus_after:bool = true

func apply():
	Comic.book.page.rebuild_lookups()
	if focus_after and o.get_parent() != null:
		Comic.book.selected_element = o
