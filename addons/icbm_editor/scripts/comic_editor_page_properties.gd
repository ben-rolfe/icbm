class_name ComicEditorPageProperties
extends ComicEditorProperties

var is_chapter:bool

@export var ref_label:Label
@export var ref_field:LineEdit
var ref: String:
	get:
		return ref
	set(value):
		if ref != value:
			print("TODO: Rename chapter or page.")
			ref = value

func prepare():
	# We don't call super - page properties is always on the left
	get_parent().get_parent().position.x = MARGIN

	# Connect signals
	ref_field.text_submitted.connect(_on_ref_field_submitted)
	ref_field.focus_exited.connect(_on_ref_field_unfocused)

	if Comic.book.bookmark.contains("/"):
		# This is a non-title page
		ref = Comic.book.bookmark.split("/")[1]
		ref_label.text = str(Comic.book.bookmark.split("/")[0], "/")
		ref_label.show()
	else:
		# This is a chapter title page
		is_chapter = true
		ref = Comic.book.bookmark
		get_child(0).text = "Chapter Properties"
		ref_label.hide()
		if Comic.book.bookmark == "start":
			ref_field.editable = false
			ref_field.focus_mode = Control.FOCUS_NONE
			ref_field.selecting_enabled = false
	ref_field.text = ref

func _on_ref_field_submitted(new_text:String):
	ref_field.release_focus()

func _on_ref_field_unfocused():
	ref_field.text = Comic.sanitize_var_name(ref_field.text)
	print("TODO: Ensure unique names")
	ref = ref_field.text
