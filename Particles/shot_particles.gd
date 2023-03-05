extends GPUParticles2D

func _ready():
	await get_tree().create_timer(5).timeout
	queue_free()
