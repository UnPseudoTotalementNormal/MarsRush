extends ColorRect

@onready var animator: AnimationPlayer = $AnimationPlayer

@onready var pause_base_container: VBoxContainer = find_child("Pause")
@onready var settings_base_container: VBoxContainer = find_child("Settings")

@onready var continue_button: Button = find_child("Continue")
@onready var settings_button: Button = find_child("gotoSettings")
@onready var menu_button: Button = find_child("Menu")

@onready var settingscategoryselector: OptionButton = find_child("SettingsCategorySelector")
@onready var exit_settings_button: Button = find_child("ExitSettings")
@onready var save_settings_button: Button = find_child("ExitAndSaveSettings")

@onready var fps_button: SpinBox = find_child("Fps")
@onready var fullscreen_button: CheckBox = find_child("FullscreenEnabler")
@onready var Vignette_button: CheckBox = find_child("Vignette")
@onready var Chromatic_button: CheckBox = find_child("ChromaticAbberation")

@onready var mobilecontrols: OptionButton = find_child("MobileControls")

var Player: RigidBody2D

func _input(event):
	if event.is_action_pressed("pause"):
		if visible:
			unpause()
		else:
			pause()


func _ready():
	visible = false
	
	continue_button.pressed.connect(unpause)
	menu_button.pressed.connect(go_to_main_menu)
	settings_button.pressed.connect(_settings)
	
	settingscategoryselector.item_selected.connect(_change_settings_category)
	
	save_settings_button.pressed.connect(_main_pause)
	exit_settings_button.pressed.connect(_main_pause)
	fps_button.value_changed.connect(_change_fps)
	mobilecontrols.item_selected.connect(_mobile_control_to)
	fullscreen_button.pressed.connect(_fullscreen)
	Vignette_button.pressed.connect(_vignette)
	Chromatic_button.pressed.connect(_chromatic_abberation)
	
	await get_tree().physics_frame
	_refresh_shown_values()

func _process(delta):
	if not Player:
		Player = get_tree().current_scene.find_child("Player", true, false)

func unpause():
	animator.play("Unpause")
	get_tree().paused = false
	visible = false

func pause():
	animator.play("Pause")
	get_tree().paused = true
	visible = true
	_refresh_shown_values()
	_main_pause()

func _main_pause():
	_go_to_category("MainPause")

func _settings():
	_refresh_shown_values()
	_go_to_category("Settings")
	_change_settings_category(0)

func _change_settings_category(category_index: int):
	var category_name: String = settingscategoryselector.get_item_text(category_index)
	for i in settings_base_container.get_children():
		if i.name == "cat_" + category_name:
			i.visible = true
		elif "cat_" in i.name:
			i.visible = false

func _go_to_category(container_name: String):
	for i in pause_base_container.get_children():
		if i.name == container_name:
			i.visible = true
		else:
			i.visible = false

func _refresh_shown_values():
	fps_button.value = Engine.physics_ticks_per_second
	
	if Player:
		var mobile_control_mode = Player.get("mobile_control_mode")
		for i in range(0, 30):
			if mobilecontrols.get_item_text(i) == mobile_control_mode:
				mobilecontrols.select(i)
		
		Vignette_button.button_pressed = Player.find_child("Vignette").visible
		Chromatic_button.button_pressed = Player.find_child("ChromaticAbberation").visible

func _apply_values():
	pass


func _fullscreen():
	if fullscreen_button.button_pressed:
		get_window().set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	else:
		get_window().set_mode(Window.MODE_WINDOWED)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _change_fps(value):
	Engine.physics_ticks_per_second = value
	_refresh_shown_values()

func _mobile_control_to(index: int):
	if Player:
		Player.set("mobile_control_mode", mobilecontrols.get_item_text(index))
	_refresh_shown_values()

func go_to_main_menu():
	get_tree().change_scene_to_file("res://Levels/menu.tscn")
	unpause()

func _vignette():
	if Player:
		Player.find_child("Vignette").visible = Vignette_button.button_pressed

func _chromatic_abberation():
	if Player:
		Player.find_child("ChromaticAbberation").visible = Chromatic_button.button_pressed
