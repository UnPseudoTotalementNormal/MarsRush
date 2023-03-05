extends ShapeCast2D
var frend = false
var damage = 45
var timer = 0.5
var radius = 30

var already_damaged = []

func _ready():
	shape.radius = radius
	if frend:
		collision_mask = $mask_frend.collision_mask
	else:
		collision_mask = $mask_bad.collision_mask
	$MeshInstance2D.mesh.radius = radius
	$MeshInstance2D.mesh.height = radius * 2
	var tween = get_tree().create_tween()
	tween.tween_property($MeshInstance2D, "modulate:a", 0, timer)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	SoundSystem.play_sound("res://sound/explosion.mp3", "explosion", 0.4, global_position)
	await get_tree().create_timer(timer).timeout
	queue_free()

func _physics_process(delta):
	force_shapecast_update()
	if is_colliding():
		for i in get_collision_count():
			if get_collider(i) not in already_damaged:
				_damage(get_collider(i))
				already_damaged.append(get_collider(i))
				if get_collider(i).has_method("_camera_shake"):
					get_collider(i)._camera_shake(0.1, 5, 0.5)

func _damage(entitie):
	if entitie.get("health_points") != null:
		entitie.set("health_points", entitie.get("health_points") - damage)
		
