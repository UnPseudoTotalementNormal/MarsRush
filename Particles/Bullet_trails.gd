extends Line2D

func _process(delta):
	modulate.a -= 3 * delta
	if modulate.a <= 0:
		queue_free()
