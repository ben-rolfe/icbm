class_name ComicEditorNote
extends CodeEdit
#NOTE: Unlike most editor controls, this doesn't extend a viewer control, because notes don't appear in the viewer.

var _data:Dictionary
var _default_data:Dictionary
var anchor_to = Vector2.ZERO

#-------------------------------------------------------------------------------

var anchor:Vector2:
	get:
		return _data_get("anchor")
	set(value):
		_data_set("anchor", value)

var content:String:
	get:
		return _data_get("content")
	set(value):
		_data_set("content", value)

var fragment:String:
	get:
		return _data_get("fragment")
	set(value):
		_data_set("fragment", value)

var layer:int:
	get:
		return _data_get("layer")
	set(value):
		_data_set("layer", value)

var oid:int:
	get:
		return _data.oid
	set(value):
		_data.oid = value

var presets:Array:
	get:
		if not _data.has("presets"):
			_data.presets = []
		return _data.presets
	set(value):
		_data.presets = value

var width:float:
	get:
		return _data_get("width")
	set(value):
		_data_set("width", value)

#-------------------------------------------------------------------------------

func _init(data:Dictionary, page:ComicPage):
	theme = Comic.theme
	_data = data
	_default_data = Comic.get_preset_data("note", presets)
	if not _data.has("oid"):
		_data.oid = Comic.book.page.make_oid()
	page.os[oid] = self
	if not _data.has("anchor"):
		_data.anchor = Vector2.ZERO
	scroll_fit_content_height = true
	wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	context_menu_enabled = false
	auto_brace_completion_highlight_matching = true
	text_changed.connect(_on_text_changed)
	caret_changed.connect(_on_changed)
	focus_entered.connect(_on_entered)
	focus_exited.connect(_on_changed)

func _data_get(key:Variant):
	return _data.get(key, _default_data[key])

func _data_set(key:Variant, value:Variant):
	if value == _default_data[key]:
		_data.erase(key)
	else:
		_data[key] = value

func apply_data():
	_default_data = Comic.get_preset_data("note", presets)
	position = anchor
	size = Vector2(width, 0)
	text = content

func rebuild(_rebuild_subobjects:bool = false):
	apply_data()
	Comic.book.page.redraw()

func after_reversion():
	rebuild()

func rebuild_widgets():
	var draw_layer:ComicWidgetLayer = Comic.book.page.layers[-1]
	draw_layer.clear()
	draw_layer.add_child(ComicNoteMoveWidget.new(self))
	draw_layer.add_child(ComicWidthWidget.new(self))

func _on_text_changed():
	if text != content:
		if not Comic.book.last_undo_matched(self, "content"):
			Comic.book.add_undo_step([ComicReversionData.new(self)])
		content = text
	_on_changed()
		
func _on_changed():
	Comic.book.page.render_target_update_mode = SubViewport.UPDATE_ONCE

func _on_entered():
	Comic.book.selected_element = self
	_on_changed()

func get_save_data() -> Dictionary:
	return _data.duplicate()
