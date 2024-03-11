class_name ComicReversionParent
extends ComicReversion

var parent

# Note: We're unparenting nodes instead of freeing them, here, and we need to avoid data leaks.
# When the redo list is cleared out, or when something is removed from the end of an undo or redo buffer, we check if it's without a parent and also without a ComicReversionParent reversion in either buffer, and if so, we free it to avoid a data leak.

func _init(o:Control, parent:Control, focus_after:bool = true):
	self.o = o
	self.parent = parent
	self.focus_after = focus_after

func apply() -> ComicReversionParent:
	var r = ComicReversionParent.new(o, o.get_parent(), focus_after)
	if parent != null:
		parent.add_child(o)
		Comic.book.page.redraw(true)
	else:
		o.get_parent().remove_child(o)
		Comic.book.page.redraw(true)
	super()
	return r
