extends ColorRect

@onready var animator: AnimationPlayer = $AnimationPlayer

@onready var pause_base_container: VBoxContainer = find_child("Pause")
@onready var continue_button: Button = find_child("Continue")
@onready var settings_button: Button = find_child("Settings")
@onready var menu_button: Button = find_child("Menu")

@onready var fps_button: SpinBox = find_child("Fps")
@onready var exit_settings_button: Button = find_child("ExitSettings")


func _ready():
	visible = false
	continue_button.pressed.connect(unpause)
	menu_button.pressed.connect(go_to_main_menu)
	settings_button.pressed.connect(_settings)
	
	exit_settings_button.pressed.connect(_main_pause)
	fps_button.value_changed.connect(_change_fps)
	
	await get_tree().physics_frame
	_refresh_shown_value()

func unpause():
	animator.play("Unpause")
	get_tree().paused = false
	visible = false

func pause():
	animator.play("Pause")
	get_tree().paused = true
	visible = true
	_go_to_category("MainPause")

func _main_pause():
	_go_to_category("MainPause")

func _settings():
	_go_to_category("Settings")

func _go_to_category(container_name: String):
	for i in pause_base_container.get_children():
		if i.name == container_name:
			i.visible = true
		else:
			i.visible = false
	$CenterContainer/PanelContainer/MarginContainer/Pause/pause_label.visible = true
	$CenterContainer/PanelContainer/MarginContainer/Pause/HSeparator.visible = true

func _change_fps(value):
	print(value)
	Engine.physics_ticks_per_second = value

func go_to_main_menu():
	get_tree().change_scene_to_file("res://Levels/menu.tscn")

func _refresh_shown_value():
	fps_button.value = Engine.physics_ticks_per_second
