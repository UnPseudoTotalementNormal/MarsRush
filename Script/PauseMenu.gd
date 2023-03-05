extends ColorRect

@onready var animator: AnimationPlayer = $AnimationPlayer

@onready var pause_base_container: VBoxContainer = find_child("Pause")
@onready var continue_button: Button = find_child("Continue")
@onready var settings_button: Button = find_child("Settings")
@onready var menu_button: Button = find_child("Menu")

@onready var fps_button: SpinBox = find_child("Fps")
@onready var fingercontrol: CheckBox = find_child("MobileFinger")
@onready var cursorcontrol: CheckBox = find_child("MobileCursor")
@onready var exit_settings_button: Button = find_child("ExitSettings")
@onready var save_settings_button: Button = find_child("ExitAndSaveSettings")


func _ready():
	visible = false
	continue_button.pressed.connect(unpause)
	menu_button.pressed.connect(go_to_main_menu)
	settings_button.pressed.connect(_settings)
	
	save_settings_button.pressed.connect(_main_pause)
	exit_settings_button.pressed.connect(_main_pause)
	fps_button.value_changed.connect(_change_fps)
	fingercontrol.pressed.connect(_mobile_finger_control)
	cursorcontrol.pressed.connect(_mobile_cursor_control)
	
	await get_tree().physics_frame
	_refresh_shown_values()

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

func _go_to_category(container_name: String):
	for i in pause_base_container.get_children():
		if i.name == container_name:
			i.visible = true
		else:
			i.visible = false
	$CenterContainer/PanelContainer/MarginContainer/Pause/pause_label.visible = true
	$CenterContainer/PanelContainer/MarginContainer/Pause/HSeparator.visible = true

func _refresh_shown_values():
	var player: RigidBody2D = get_tree().current_scene.find_child("Player")
	fps_button.value = Engine.physics_ticks_per_second
	
	if player != null:
		var mobile_control_mode = player.get("mobile_control_mode")
		if mobile_control_mode == "finger":
			fingercontrol.button_pressed = true
			cursorcontrol.button_pressed = false
		elif mobile_control_mode == "cursor":
			fingercontrol.button_pressed = false
			cursorcontrol.button_pressed = true




func _change_fps(value):
	Engine.physics_ticks_per_second = value
	_refresh_shown_values()

func _mobile_finger_control():
	var player: RigidBody2D = get_tree().current_scene.find_child("Player")
	if player != null:
		player.set("mobile_control_mode", "finger")
	_refresh_shown_values()

func _mobile_cursor_control():
	var player: RigidBody2D = get_tree().current_scene.find_child("Player")
	if player != null:
		player.set("mobile_control_mode", "cursor")
	_refresh_shown_values()

func go_to_main_menu():
	get_tree().change_scene_to_file("res://Levels/menu.tscn")
