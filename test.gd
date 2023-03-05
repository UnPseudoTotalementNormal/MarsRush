extends MeshInstance2D

func _physics_process(delta):
	if Input.is_action_pressed("ui_right"):
		rotation_degrees += 100 * delta
	if Input.is_action_pressed("ui_left"):
		rotation_degrees -= 100 * delta
