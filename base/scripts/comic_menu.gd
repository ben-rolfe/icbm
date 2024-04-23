class_name ComicMenu
extends Window

var buttons:VBoxContainer

func _init():
	exclusive = true
	close_requested.connect(queue_free)

	buttons = VBoxContainer.new()
	add_child(buttons)
	buttons.resized.connect(_on_buttons_resized)
	var save_button:Button = Button.new()
	buttons.add_child(save_button)
	save_button.text = "Save"
	save_button.pressed.connect(_on_save_pressed)
	var load_button:Button = Button.new()
	buttons.add_child(load_button)
	load_button.text = "Load"
	load_button.pressed.connect(_on_load_pressed)
	var quit_button:Button = Button.new()
	buttons.add_child(quit_button)
	quit_button.text = "Quit"
	quit_button.pressed.connect(_on_quit_pressed)

static func open():
	var menu:ComicMenu = ComicMenu.new()
	Comic.add_child(menu)
	menu.popup_centered()

func _on_quit_pressed():
	Comic.request_quit()

func _on_save_pressed():
	hide()
	ComicSavesMenu.open(true)
	queue_free()

func _on_load_pressed():
	hide()
	ComicSavesMenu.open(false)
	queue_free()

func _on_buttons_resized():
	size = Vector2(min(buttons.size.x, Comic.size.x - 80), min(buttons.size.y, Comic.size.y - 80))
	move_to_center()
