class_name ComicEditorFragmentProperties
extends ComicEditorProperties

var page:ComicEditorPage
var key:String

@export var key_lineedit:LineEdit

@export var show_textedit:TextEdit
@export var show_in_editor_checkbox:CheckBox
var show_before_changes:String

@export var delete_button:Button


func _ready():
	show_textedit.text_changed.connect(_on_show_textedit_changed)	
	show_textedit.caret_blink = true
	show_textedit.focus_entered.connect(_on_show_textedit_focused)
	show_textedit.focus_exited.connect(_on_show_textedit_unfocused)

	key_lineedit.text_submitted.connect(_on_key_lineedit_submitted)
	key_lineedit.focus_exited.connect(_on_key_lineedit_unfocused)

	show_in_editor_checkbox.toggled.connect(_on_show_in_editor_checkbox_toggled)

	delete_button.pressed.connect(_on_delete_pressed)

func prepare():
	super()
	page = Comic.book.page
	if "fragment" in Comic.book.selected_element:
		# If we opened this panel from the background, then we already set the key directly.
		key = Comic.book.selected_element.fragment
	key_lineedit.text = key.capitalize()
	show_textedit.text = ComicEditor.parse_text_edit(page.data.fragments[key].show)
	show_in_editor_checkbox.button_pressed = page.data.fragments[key].show_in_editor

func _on_key_lineedit_submitted(new_text:String):
	key_lineedit.release_focus()

func _on_key_lineedit_unfocused():
	var new_key = Comic.validate_name(key_lineedit.text)
	if new_key == "":
		new_key = "fragment_1"
	if new_key != key:
		new_key = ComicEditor.get_unique_array_item(Comic.book.page.data.fragments.keys(), new_key)
		page.rename_fragment(key, new_key)
		key = new_key
	key_lineedit.text = key.capitalize()

func _on_show_textedit_changed():
	page.data.fragments[key].show = ComicEditor.unparse_text_edit(show_textedit.text)
	page.rebuild(true)

func _on_show_textedit_focused():
	show_before_changes = show_textedit.text
	
func _on_show_textedit_unfocused():
	if show_textedit.text != show_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(page)
		reversion.data.fragments[key].show = ComicEditor.unparse_text_edit(show_before_changes)
		Comic.book.add_undo_step([reversion])

func _on_show_in_editor_checkbox_toggled(toggled_on:bool):
	Comic.book.add_undo_step([ComicReversionData.new(page)])
	page.data.fragments[key].show_in_editor = toggled_on
	page.redraw()

func _on_delete_pressed():
	Comic.confirm("Delete Fragment?", "You are about to delete this fragment.\n\nContents of the fragment will not be deleted.\n\nAre you sure you want to delete the fragment?", delete)

func delete():
	page.delete_fragment(key)
	Comic.book.open_properties = null
	page.redraw()
