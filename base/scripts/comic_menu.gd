class_name ComicMenu
extends Window

var buttons:VBoxContainer

func _init():
	exclusive = true
	close_requested.connect(queue_free)

	buttons = VBoxContainer.new()
	add_child(buttons)
	buttons.resized.connect(_on_buttons_resized)

	if Comic.book.bookmark != "start":
		var home_button:Button = Button.new()
		buttons.add_child(home_button)
		home_button.text = "Back to Main Menu"
		home_button.pressed.connect(_on_home_pressed)

	# Only show the save button if the comic and the page both allow manual saving.
	if Comic.book.manual_save_slots and Comic.book.page.allow_save:
		var save_button:Button = Button.new()
		buttons.add_child(save_button)
		save_button.text = "Save"
		save_button.pressed.connect(_on_save_pressed)

	# Only show the load button if there are any saves, and either manual saves are allowed, or this ISN'T an autosaved page.
	# (Because if it's auto-save only, and we've just autosaved, then there's no sense in reloading.
	if Comic.save_exists() and (Comic.book.manual_save_slots or not Comic.book.page.auto_save):
		var load_button:Button = Button.new()
		buttons.add_child(load_button)
		load_button.text = "Load" if Comic.book.manual_save_slots else "Load auto-save"
		load_button.pressed.connect(_on_load_pressed)
	var quit_button:Button = Button.new()
	buttons.add_child(quit_button)
	quit_button.text = "Quit"
	quit_button.pressed.connect(_on_quit_pressed)

static func open():
	var menu:ComicMenu = ComicMenu.new()
	Comic.add_child(menu)
	menu.popup_centered()

func _on_home_pressed():
	hide()
	Comic.book.start()
	queue_free()

func _on_quit_pressed():
	hide()
	Comic.request_quit()
	queue_free()

func _on_save_pressed():
	hide()
	ComicSavesMenu.open(true)
	queue_free()

func _on_load_pressed():
	hide()
	if Comic.book.manual_save_slots:
		ComicSavesMenu.open(false)
	else:
		# Comic is auto-save-only - don't open the menu, just load the auto-save
		Comic.load_savefile(0)
	queue_free()

func _on_buttons_resized():
	size = Vector2(min(buttons.size.x, Comic.size.x - 80), min(buttons.size.y, Comic.size.y - 80))
	move_to_center()
