class_name ComicEditorButton
extends ComicButton

func activate():
	Comic.book.selected_element = self
	Comic.book.open_properties = Comic.book.button_properties

func rebuild(_rebuild_subobjects:bool = false):
	apply_data()

func after_reversion():
	rebuild()
