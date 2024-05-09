class_name ComicEditorSettingsProperties
extends ComicEditorProperties

@export var snap_to_grid_check_box:CheckBox
@export var show_grid_check_box:CheckBox
@export var grid_x_spin_box:SpinBox
@export var grid_y_spin_box:SpinBox

func _ready():
	snap_to_grid_check_box.toggled.connect(_on_snap_to_grid_check_box_toggled)
	show_grid_check_box.toggled.connect(_on_show_grid_check_box_toggled)
	grid_x_spin_box.value_changed.connect(_on_grid_value_changed)
	grid_y_spin_box.value_changed.connect(_on_grid_value_changed)

func prepare():
	snap_to_grid_check_box.button_pressed = ComicEditor.snap_on
	show_grid_check_box.button_pressed = ComicEditor.grid_on
	grid_x_spin_box.value = ComicEditor.snap_distance.x
	grid_y_spin_box.value = ComicEditor.snap_distance.y

func _on_snap_to_grid_check_box_toggled(toggled_on:bool):
	ComicEditor.snap_on = toggled_on
	ComicEditor.save_setting("snap_on", toggled_on)

func _on_show_grid_check_box_toggled(toggled_on:bool):
	print("Show toggled ", toggled_on)
	ComicEditor.grid_on = toggled_on
	ComicEditor.save_setting("grid_on", toggled_on)
	Comic.book.page.background.rebuild()
	Comic.book.page.redraw()
#	Comic.book.page.rebuild()

func _on_grid_value_changed(new_value:float):
	ComicEditor.snap_distance = Vector2(grid_x_spin_box.value, grid_y_spin_box.value)
	ComicEditor.save_setting("snap_distance", ComicEditor.snap_distance)
	if ComicEditor.grid_on:
		Comic.book.page.rebuild()
