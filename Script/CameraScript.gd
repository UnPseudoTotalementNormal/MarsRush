extends Camera2D
var dtime: float

var cam_follow_timer_await = false
var cam_follow_pause = false
var cam_follow_prev_pos = Vector2.ZERO
@export var cam_follow_zoom = Vector2(0.686, 0.686)
@export var cam_pause_zoom = Vector2(0.5, 0.5)

func _physics_process(delta):
	dtime = delta

func camera_shake(duration: float = 1, shake_size: float = 10, force: float = 0.5):
	var timer = get_tree().create_timer(duration)
	while timer.time_left > 0:
		randomize()
		var random_x = randf_range(-shake_size, shake_size)
		var random_y = randf_range(-shake_size, shake_size)
		offset = lerp(offset, Vector2(random_x, random_y), force)
#		offset = Vector2(random_x, random_y)
		await get_tree().physics_frame
	offset = Vector2.ZERO

func follow(follow, priority: int = 1):
	if cam_follow_prev_pos == Vector2.ZERO:
		cam_follow_prev_pos = follow.global_position
	
	var cam = get_viewport().get_camera_2d()
	if not cam_follow_pause:
		global_position = follow.global_position
		zoom = lerp(zoom, cam_follow_zoom, 1 * dtime)
#		if not cam_follow_timer_await:
#			cam_follow_timer_await = true
#			await get_tree().create_timer(8).timeout
#			cam_follow_timer_await = false
#			if (follow.global_position - cam_follow_prev_pos).length() < 75:
#				cam_follow_pause = true
#				cam_follow_prev_pos = Vector2.ZERO
#				return
#			cam_follow_prev_pos = follow.global_position
#	else:
#		zoom = lerp(zoom, cam_follow_zoom / 1.5, 1 * dtime)
#		if (global_position - follow.global_position).length() >= 150 or abs(global_position.y - follow.global_position.y) >= 100:
#			cam_follow_pause = false
