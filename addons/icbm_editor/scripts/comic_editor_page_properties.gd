class_name ComicEditorPageProperties
extends ComicEditorProperties

# We could access page through Comic, but we'll set it in a variable for convenience and consistency with other ComicEditorXxProperties scripts
var page:ComicEditorPage
var is_chapter:bool

@export var action_button:OptionButton
@export var action_target_button:OptionButton
@export var action_commands_textedit:TextEdit

var commands_before_changes:String

@export var chapter_row:HBoxContainer
@export var chapter_button:OptionButton
@export var new_name_label:Label
@export var new_name_lineedit:LineEdit

var original_chapter_name:String = ""
var original_page_name:String = ""

func _ready():
	chapter_button.item_selected.connect(_on_chapter_item_selected)

	for action in ComicButton.Action:
		action_button.add_item(action.capitalize(), ComicButton.Action[action])
	action_button.item_selected.connect(_on_action_item_selected)
	for bookmark in Comic.book.bookmarks:
		action_target_button.add_item(bookmark)
	action_target_button.item_selected.connect(_on_action_target_item_selected)

	action_commands_textedit.text_changed.connect(_on_commands_textedit_changed)	
	action_commands_textedit.caret_blink = true
	action_commands_textedit.focus_entered.connect(_on_commands_textedit_focused)
	action_commands_textedit.focus_exited.connect(_on_commands_textedit_unfocused)

	new_name_lineedit.text_submitted.connect(_on_new_name_submitted)
	new_name_lineedit.focus_exited.connect(_on_new_name_unfocused)


func prepare():
	page = Comic.book.page

	# We don't call super - page properties is always on the left
	get_parent().get_parent().position.x = MARGIN
	
	if original_chapter_name == "":
		# First time opening the page settings.
		if page.bookmark.contains("/"):
			original_chapter_name = page.bookmark.split("/")[0]
			page.data.new_chapter = original_chapter_name
			original_page_name = page.bookmark.split("/")[1]
			page.data.new_name = original_page_name
			for key in Comic.book.pages:
				chapter_button.add_item(key)
				if key == original_chapter_name:
					chapter_button.select(chapter_button.item_count - 1)
		else:
			chapter_row.hide()
			get_child(0).text = "Chapter Properties"
			new_name_label.text = "Name:"
			original_chapter_name = page.bookmark
			page.data.new_name = original_chapter_name
			if page.bookmark == "start":
				new_name_lineedit.editable = false

	new_name_lineedit.text = page.data.new_name

	action_button.select(page.action)
	after_action_changed()

func _on_new_name_submitted(new_text:String):
	new_name_lineedit.release_focus()

func _on_new_name_unfocused():
	new_name_lineedit.text = Comic.sanitize_var_name(new_name_lineedit.text)
	print("TODO: Ensure unique names")
	if original_page_name == "":
		# This is a title page - we're trying to change a CHAPTER name
		if new_name_lineedit.text != original_chapter_name and Comic.book.pages.has(new_name_lineedit.text):
			# Chapter name already exists, revert to original
			new_name_lineedit.text = original_chapter_name
	else:
		# This is a non-title page - we're trying to change a page name
		if page.data.new_chapter != original_chapter_name or new_name_lineedit.text != original_page_name:
			# Page name or chapter has changed, so ensure unique page name within chapter
			if Comic.book.pages[page.data.new_chapter].has(new_name_lineedit.text):
				# Page name already exists - do something about it
				if page.data.new_chapter == original_chapter_name or not Comic.book.pages[page.data.new_chapter].has(original_page_name):
					# We haven't changed chapters, or the new chapter doesn't have a page matching the original name, so just revert to the original name
					new_name_lineedit.text = original_page_name
				else:
					# We've changed chapters, and a page of the original name exists within the new chapter, so generate a new name
					var i = 1
					while Comic.book.pages[page.data.new_chapter].has(str("page_", i)):
						i += 1
					new_name_lineedit.text = str("page_", i)
	page.data.new_name = new_name_lineedit.text

func after_action_changed():
	match page.action:
		ComicButton.Action.GO, ComicButton.Action.VISIT:
			action_commands_textedit.hide()
			action_target_button.show()
			page.action_commands = ""
			# If bookmark is blank, default to the next page, otherwise, set it.
			action_target_button.select(Comic.book.get_relative_bookmark_index(page.bookmark, 1) if page.action_bookmark == "" else Comic.book.bookmarks.find(page.action_bookmark))

		ComicButton.Action.PARSE_COMMANDS:
			action_target_button.hide()
			action_commands_textedit.show()
			page.action_bookmark = ""
			action_commands_textedit.text = page.action_commands

		_:
			action_target_button.hide()
			action_commands_textedit.hide()
			page.action_bookmark = ""
			page.action_commands = ""

func _on_action_item_selected(index:int):
	if page.action != index:
		Comic.book.add_undo_step([ComicReversionData.new(page)])
		page.action = index
		page.rebuild(true)
		after_action_changed()

func _on_action_target_item_selected(index:int):
	Comic.book.add_undo_step([ComicReversionData.new(page)])
	page.action_bookmark = Comic.book.bookmarks[index]
	page.rebuild(true)

func _on_chapter_item_selected(index:int):
	page.data.new_chapter = chapter_button.get_item_text(index)
	# We make sure that the page name is appropriate for the new chapter:
	_on_new_name_unfocused()

func _on_commands_textedit_changed():
	page.action_commands = ComicEditor.unparse_text_edit(action_commands_textedit.text)
	page.rebuild(true)

func _on_commands_textedit_focused():
	commands_before_changes = action_commands_textedit.text
	
func _on_commands_textedit_unfocused():
	if action_commands_textedit.text != commands_before_changes:
		var reversion:ComicReversionData = ComicReversionData.new(page)
		reversion.data.action_commands = ComicEditor.unparse_text_edit(commands_before_changes)
		Comic.book.add_undo_step([reversion])
