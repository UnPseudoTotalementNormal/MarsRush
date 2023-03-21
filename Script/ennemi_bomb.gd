extends RigidBody2D
var from = null
var explosion = preload("res://Entities/explosion.tscn")
var health_points = 40


func _ready():
	pass


func _physics_process(delta):
	if health_points <= 0:
		_explode()
	
	if get_colliding_bodies().size() > 0:
		_explode()


func _explode():
	var exp = explosion.instantiate()
	exp.set("from", from)
	exp.set("frend", false)
	exp.set("damage", 40)
	exp.global_position = global_position
	exp.set("timer", 0.5)
	exp.set("radius", 45)
	get_tree().current_scene.add_child(exp)
	queue_free()
