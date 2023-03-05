extends ColorRect

@onready var animator: AnimationPlayer = $AnimationPlayer

@onready var continue_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Continue
@onready var menu_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Menu

func _ready():
	visible = false
	continue_button.pressed.connect(unpause)
	menu_button.pressed.connect(go_to_main_menu)

func unpause():
	animator.play("Unpause")
	get_tree().paused = false
	visible = false

func pause():
	animator.play("Pause")
	get_tree().paused = true
	visible = true

func go_to_main_menu():
	get_tree().change_scene_to_file("res://Levels/menu.tscn")
