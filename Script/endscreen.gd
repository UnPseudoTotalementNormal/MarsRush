extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Label.position.y -= 25 * delta
	if $Label.position.y < -402:
		get_tree().change_scene_to_file("res://Levels/menu.tscn")
