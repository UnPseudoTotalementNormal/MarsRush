extends CharacterBody2D
var RigidLeg = preload("res://Entities/leg_rigid_body.tscn")
@onready var collision = $CollisionShape2D

var health_points: float = 5
var percent_damage: float = 0.10

func _ready():
	var spider = $"../../..".get_parent().get_parent().get_parent()
	collision.shape.size = Vector2(get_parent().mesh.size.x, get_parent().mesh.size.y)
	health_points = spider.get("legs_max_health")
	percent_damage = spider.get("percentage_damage_per_leg_destroyed")

func _process(delta):
	if health_points <= 0:
		var spider = $"../../..".get_parent().get_parent().get_parent()
		var legscene = $"../../.."
		if spider.get("health_points") != null:
			spider.set("health_points", spider.get("health_points") - spider.get("max_health") * percent_damage)
			if spider.has_method("lost_a_leg"):
				spider.lost_a_leg()
			var LegSpawner: RigidBody2D = RigidLeg.instantiate()
			LegSpawner.global_position = global_position
			LegSpawner.find_child("leg1").modulate = legscene.find_child("MeshInstance2D").modulate
			LegSpawner.find_child("leg2").modulate = legscene.find_child("MeshInstance2D2").modulate
			var rand_speed = 30
			LegSpawner.linear_velocity = Vector2(randf_range(-rand_speed, rand_speed), randf_range(-rand_speed, rand_speed))
			LegSpawner.rotation_degrees = legscene.find_child("LegPivot1").rotation_degrees
			get_tree().current_scene.add_child(LegSpawner)
		legscene.get_parent().queue_free() #delete the leg
		
