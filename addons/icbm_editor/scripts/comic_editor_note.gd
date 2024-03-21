class_name ComicEditorNote
extends CodeEdit
#NOTE: Unlike most editor controls, this doesn't extend a viewer control, because notes don't appear in the viewer.

var data:Dictionary
var default_data:Dictionary

#-------------------------------------------------------------------------------

var anchor:Vector2:
	get:
		return _data_get("anchor")
	set(value):
		_data_set("anchor", value)

var layer:int:
	get:
		return _data_get("layer")
	set(value):
		_data_set("layer", value)

var oid:int:
	get:
		return data.oid
	set(value):
		data.oid = value

var width:float:
	get:
		return _data_get("width")
	set(value):
		_data_set("width", value)

#-------------------------------------------------------------------------------

func _init(data:Dictionary, page:ComicPage):
	theme = Comic.theme
	self.data = data
	default_data = _get_default_data()
	if not data.has("oid"):
		data.oid = Comic.book.page.make_oid()
	page.os[oid] = self
	if not data.has("anchor"):
		data.anchor = Vector2.ZERO
	scroll_fit_content_height = true
	wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	context_menu_enabled = false
	auto_brace_completion_highlight_matching = true
	text_changed.connect(_on_text_changed)
	caret_changed.connect(_on_changed)
	focus_entered.connect(_on_changed)
	focus_exited.connect(_on_changed)

func _data_get(key:Variant):
	return data.get(key, default_data[key])

func _data_set(key:Variant, value:Variant):
	if value == default_data[key]:
		data.erase(key)
	else:
		data[key] = value

func apply_data():
	position = anchor
	size = Vector2(width, 0)
	text = _data_get("text")

func rebuild(_rebuild_subobjects:bool = false):
	apply_data()
	Comic.book.page.redraw()

func after_reversion():
	rebuild()

func _on_text_changed():
	if text != _data_get("text"):
		if not Comic.book.last_undo_matched(self, "text"):
			Comic.book.add_undo_step([ComicReversionData.new(self)])
		_data_set("text", text)
	_on_changed()
		
func _on_changed():
	Comic.book.page.render_target_update_mode = SubViewport.UPDATE_ONCE

static func _get_default_data() -> Dictionary:
	return {
		"anchor": Vector2.ZERO,
		"layer": 0,
		"text": "",
		"width": Comic.theme.get_constant("width", "Balloon"),
	}
