class_name ComicEditorSettingsProperties
extends ComicEditorProperties

const IMAGE_QUALITY_OPTIONS = {
	"Keep Original": -1,
	"100% (Lossless)": 100,
	"90%": 90,
	"80%": 80,
	"70%": 70,
	"60%": 60,
	"50%": 50,
	"40%": 40,
	"30%": 30,
	"20%": 20,
	"10%": 10,
}

@export var snap_to_grid_check_box:CheckBox
@export var show_grid_check_box:CheckBox
@export var grid_x_spin_box:SpinBox
@export var grid_y_spin_box:SpinBox
@export var image_quality_button:OptionButton

func _ready():
	snap_to_grid_check_box.toggled.connect(_on_snap_to_grid_check_box_toggled)
	show_grid_check_box.toggled.connect(_on_show_grid_check_box_toggled)
	grid_x_spin_box.value_changed.connect(_on_grid_value_changed)
	grid_y_spin_box.value_changed.connect(_on_grid_value_changed)

	for key in IMAGE_QUALITY_OPTIONS:
		image_quality_button.add_item(key)
		image_quality_button.set_item_metadata(-1, IMAGE_QUALITY_OPTIONS[key])
		
	image_quality_button.item_selected.connect(_on_image_quality_button_item_selected)

func prepare():
	snap_to_grid_check_box.button_pressed = ComicEditor.snap_on
	show_grid_check_box.button_pressed = ComicEditor.grid_on
	grid_x_spin_box.value = ComicEditor.snap_distance.x
	grid_y_spin_box.value = ComicEditor.snap_distance.y
	
	for i in image_quality_button.item_count:
		if image_quality_button.get_item_metadata(i) == Comic.book.image_quality:
			image_quality_button.select(i)
			break

func _on_snap_to_grid_check_box_toggled(toggled_on:bool):
	ComicEditor.snap_on = toggled_on
	Comic.config.set_value("editor", "snap_on", toggled_on)

func _on_show_grid_check_box_toggled(toggled_on:bool):
	print("Show toggled ", toggled_on)
	ComicEditor.grid_on = toggled_on
	Comic.config.set_value("editor", "grid_on", toggled_on)
	Comic.book.page.background.rebuild()
	Comic.book.page.redraw()
#	Comic.book.page.rebuild()

func _on_grid_value_changed(new_value:float):
	ComicEditor.snap_distance = Vector2(grid_x_spin_box.value, grid_y_spin_box.value)
	Comic.config.set_value("editor", "snap_distance", ComicEditor.snap_distance)
	if ComicEditor.grid_on:
		Comic.book.page.rebuild()

func _on_image_quality_button_item_selected(index:int):
	Comic.book.image_quality = image_quality_button.get_item_metadata(index)
	Comic.book.page.background.rebuild()
	Comic.book.page.redraw()
