extends StaticBody2D
var health_points = 10

func _process(delta):
	if health_points <= 0:
		get_tree().change_scene_to_file("res://Levels/menu.tscn")
