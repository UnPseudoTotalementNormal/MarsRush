extends StaticBody2D
var health_points = 20

func _process(delta):
	if health_points <= 0:
		queue_free()
