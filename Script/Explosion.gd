extends ShapeCast2D
var from = null

var frend = false
var damage = 45
var timer = 0.5
var radius = 30

var already_damaged = []

var camera: Camera2D

func _ready():
	camera = get_viewport().get_camera_2d()
	shape.radius = radius
	if frend:
		collision_mask = $mask_frend.collision_mask
	else:
		collision_mask = $mask_bad.collision_mask
	$MeshInstance2D.mesh.radius = radius
	$MeshInstance2D.mesh.height = radius * 2
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0, timer)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	var light_tween = get_tree().create_tween()
	light_tween.tween_property($PointLight2D, "energy", 0, timer)
	light_tween.set_ease(Tween.EASE_OUT)
	light_tween.set_trans(Tween.TRANS_CUBIC)
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
				if get_collider(i).global_position == camera.global_position:
					camera.camera_shake(0.3, 8, 0.7)

func _damage(entitie):
	if entitie.has_method("get_damaged"):
		entitie.get_damaged(damage, true, from)
	elif entitie.get("health_points") != null:
		entitie.set("health_points", entitie.get("health_points") - damage)
