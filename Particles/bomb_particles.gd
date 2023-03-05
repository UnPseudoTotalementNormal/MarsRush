extends GPUParticles2D
var bomb: RigidBody2D = null
var can_die = false

# Called when the node enters the scene tree for the first time.
func _ready():
	emitting = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if bomb != null:
		emitting = true
		global_position = bomb.global_position
		can_die = true
	if bomb == null and can_die:
		emitting = false
		await get_tree().create_timer(3).timeout
		queue_free()
