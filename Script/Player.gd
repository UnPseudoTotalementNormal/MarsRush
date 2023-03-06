extends RigidBody2D
var shoot_particles = preload("res://Particles/shot_particles.tscn")
var bullet_trail = preload("res://Particles/Bullet_trails.gd")
var shoot_limit = preload("res://Entities/shoot_limit.tscn")
var gun_spawn = preload("res://Entities/player_gun.tscn")
var dpart = preload("res://Entities/death_part.tscn")
var foampart = preload("res://Particles/cloudparticles.tscn")
var dtime: float = 0.0

var camera_follow_player = true
var cam_follow_timer_await = false
var cam_follow_pause = false
var cam_follow_prev_pos = Vector2.ZERO
@export var cam_follow_zoom = Vector2(0.686, 0.686)
@export var cam_pause_zoom = Vector2(0.5, 0.5)

@export var gun_move_range = 40
@export var gun_punch_force = 100 #how much pushing a wall will push u back
@export var gun_shoot_force = 10000 #how much shooting will push u back
@export var gun_shoot_range = 200
@export var gun_shoot_spread = 0.2 #1.0 = 100% 0.5 = 50% etc
@export var gun_shoot_bullet_number = 3
@export var gun_shoot_damage = 25
@export var gun_max_ammo = 2
@export var gun_reload_time = 1.5 #in seconds
@export var extinguisher_oxygen_cost = 25
@export var extinguisher_force = 12500
var gun_current_ammo = 2
var gun_hud_ammo_size = 217
var equipped = "hand"
var inventory = ["hand", "gun", "extinguisher"]

var reloading = false
var grabbing = false
var grabbed = null
var previous_grabbed_vel = Vector2.ZERO

@export var max_health: float = 100
@export var max_oxygen: float = 100
@export var health_regen_wait: float = 3
@export var oxygen_regen_wait: float = 2
var previous_health_point: float = 100
var previous_oxygen_point: float = 100
var health_points: float = 100
var oxygen_points: float = 100
var in_space: bool = false
var dead = false

var Gun: CharacterBody2D
var gun_lim: CharacterBody2D
var gun_reload_hud_tween: Tween
var old_gun_vel: Vector2 = Vector2.ZERO #BEFORE IMPACT
var test_marker: MeshInstance2D = null
var grabjoint: PinJoint2D = null

@onready var rleg = $RightLeg
@onready var lleg = $LeftLeg
@onready var legpos = $Legspos
@onready var armpos = $Armpos
@onready var larm = $LeftArm
@onready var rarm = $RightArm
@onready var ramesh = $RightArm/MeshInstance2D
@onready var mousemarker = $MousePivot/MouseMarker

var cursor_position: Vector2 = Vector2.ZERO

####mobile only vars####
var mobile: bool = false
var shoot_button_pressed: bool = false
var mobile_sensitivity: float = 1.0
var old_mouse_pos: Vector2 = Vector2.ZERO
var ignore_next_mouse_pos: bool = true

var mobile_control_mode = "Cursor" #available mode: Finger, Cursor, (NOT YET) Joystick
########################

func _ready():
	if OS.get_name() == "Android" or OS.get_name() == "IOS":
		mobile = true
	else:
		$HUD/TouchScreensButtons.hide()
	$Pivot/Gun_pos.position.x = gun_move_range
	_search_gun()

func _mobile():
	var leftclickshootevent = InputMap.action_get_events("shoot")
	if leftclickshootevent.size() > 0:
		InputMap.action_erase_event("shoot", leftclickshootevent[0])

		
func _search_gun():
	var search_gun = get_tree().current_scene.find_child("Player_Gun", true, false)
	if search_gun != null:
		Gun = search_gun
		await get_tree().physics_frame
		gun_lim = shoot_limit.instantiate()
		get_tree().current_scene.add_child(gun_lim)
		$HUD/Ammo.visible = true

func _spawn_gun():
	var gspawn = gun_spawn.instantiate()
	gspawn.global_position = global_position
	get_tree().current_scene.add_child(gspawn)

func _input(event):
	if mobile:
		return
	
	if event.is_action_pressed("pause"):
		$HUD/PauseMenu.pause()
	
	if event is InputEventKey:
		if not event.echo and event.is_pressed():
			if event.physical_keycode >= 48 and event.physical_keycode <= 57:
				_equip_specific(event.physical_keycode - 49)
	if event.is_action_pressed("easteregg"):
		if inventory.has("extinguisher") and not inventory.has("airhorn"):
			inventory.erase("extinguisher")
			inventory.append("airhorn")
	if event is InputEventMouseButton:
		if event.button_mask != 0 and event.button_index == 1:
			if Gun != null:
				_shoot_with_equipped_once()

func _custom_mouse_velocity():
	$MousePivot.global_position = global_position
	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return
	var CustomMouseVel: Vector2 = cam.get_local_mouse_position() - old_mouse_pos
	
	if not ignore_next_mouse_pos:
		mousemarker.position += CustomMouseVel * mobile_sensitivity
		mousemarker.position = clamp(mousemarker.position, -get_viewport_rect().size, get_viewport_rect().size)
	
	if not old_mouse_pos.is_equal_approx(cam.get_local_mouse_position()): 
		ignore_next_mouse_pos = false
	else: 
		ignore_next_mouse_pos = true
	old_mouse_pos = cam.get_local_mouse_position()

func _custom_mouse_position():
	$MousePivot.global_position = global_position
	if mobile:
		var cam = get_viewport().get_camera_2d()
		if cam.get_local_mouse_position().x < -169:
			return
	mousemarker.global_position = get_global_mouse_position()

func _equip_w_mouse_wheel(next: int = 1):
	var equipping = inventory.find(equipped) + next
	equipping = wrapi(equipping, 0, inventory.size())
	equipping = inventory[equipping]
	equipped = equipping

func _equip_specific(number: int = -1):
	if number <= inventory.size() - 1 and number != -1:
		equipped = inventory[number]

func _mouse_system():
	if not mobile or mobile_control_mode == "Finger":
		_custom_mouse_position() #normal mouse/finger system
	elif mobile_control_mode == "Cursor":
		_custom_mouse_velocity() #move the cursor with finger

func _physics_process(delta):
	dtime = delta
	SoundSystem.space_audio = in_space
	if dead:
		return
	_mouse_system()
	
	
	if mobile:
		_mobile()
	
	if Gun != null:
		_gun_position()
		if not grabbing:
			_gun_velocity()
			_gun_collision()
		else:
			_grab_with_hand_physics()
		_gun_sprite()
		_gun_shoot_limit()
		_gun_hud()
		_gun_reloading()
		if Input.is_action_just_released("equip_next"):
			_equip_w_mouse_wheel(1)
		elif Input.is_action_just_released("equip_previous"):
			_equip_w_mouse_wheel(-1)
		if Input.is_action_pressed("shoot") or shoot_button_pressed:  #shoot_button_pressed = mobile button
			_shoot_with_equipped()
		if Input.is_action_just_released("shoot") and grabbing:
			_ungrab_with_hand()
		Gun.move_and_slide()
	else:
		$HUD/Ammo.visible = false
		_spawn_gun()
		_search_gun()
	
	_oxygen()
	_health_hud()
	_health_regen()
	_body_movement() #visual only
	if camera_follow_player and get_viewport().get_camera_2d() != null:
		_camera_follow(self)
	
	if health_points <= 0 or Input.is_action_just_pressed("restart"):
		_death()
	
	
	

func _health_regen():
	if previous_health_point > health_points:
		$Health_regen.start(health_regen_wait)
	previous_health_point = health_points
	if $Health_regen.is_stopped():
		if health_points >= max_health:
			health_points = max_health
		else:
			health_points += 10 * dtime

func _health_hud():
	$HUD/Health.value = health_points
	if health_points != max_health:
		$HUD/Health.visible = true
	else:
		$HUD/Health.visible = false


func _death():
	dead = true
	visible = false
	Gun.queue_free()
	gun_lim.queue_free()
	var deathpart = dpart.instantiate()
	deathpart.global_position = global_position
	get_tree().current_scene.add_child(deathpart)
	if get_tree().current_scene.has_method("_respawn"):
		get_tree().current_scene._respawn(1.5)
		queue_free()


func _oxygen():
	if oxygen_points <= 0:
		_death()
	if oxygen_points < 100:
		$HUD/Oxygen.visible = true
	else:
		$HUD/Oxygen.visible = false
	$HUD/Oxygen.value = oxygen_points
	
	if previous_oxygen_point > oxygen_points:
		$Oxygen_regen.start(oxygen_regen_wait)
	
	if in_space:
		oxygen_points -= 2.5 * dtime
	elif oxygen_points < max_oxygen:
		if $Oxygen_regen.is_stopped():
			if oxygen_points >= max_oxygen:
				oxygen_points = max_oxygen
			else:
				oxygen_points += 10 * dtime
	
	previous_oxygen_point = oxygen_points



func _gun_shoot_limit():
	if gun_lim != null:
		var limrange = gun_shoot_range / 10
		gun_lim.get_child(0).scale = Vector2(limrange, limrange)
		gun_lim.global_position = Gun.global_position
	

func _go_opposite_of_mouse(force):
	apply_central_impulse((global_position - mousemarker.global_position).normalized() * force)

func _gun_position():
	$Pivot.look_at(mousemarker.global_position)
	if (global_position - mousemarker.global_position).length() <= gun_move_range + 10:
		if equipped == "gun":
			$Pivot/Gun_pos.position.x = (global_position - mousemarker.global_position).length() - 10
		else:
			$Pivot/Gun_pos.position.x = (global_position - mousemarker.global_position).length() - 0.1
	else:
		if equipped == "gun":
			$Pivot/Gun_pos.position.x = gun_move_range
		else:
			$Pivot/Gun_pos.position.x = gun_move_range + 10
	Gun.look_at(mousemarker.global_position)
	

func _gun_velocity():
	var gun_vector = $Pivot/Gun_pos.global_position - Gun.global_position
	Gun.velocity = gun_vector * 10
	Gun.velocity += linear_velocity

func _gun_collision():
	if Gun.get_slide_collision_count() > 0:
		apply_central_impulse(-Gun.velocity * gun_punch_force * dtime)
	else:
		old_gun_vel = Gun.velocity
	
	#nogunsprite in _gun_sprite()
	if equipped == "gun":
		Gun.find_child("noguncoll").set_deferred("disabled", true)
		Gun.find_child("CollisionShape2D").set_deferred("disabled", false)
	else:
		Gun.find_child("noguncoll").set_deferred("disabled", false)
		Gun.find_child("CollisionShape2D").set_deferred("disabled", true)
	

func _body_follow_mouse():
	pass
#	if abs(angular_velocity) < 0.1 and angular_velocity != 0:
#		angular_velocity = 0

func _shoot_with_equipped():
	if equipped == "hand":
		if not grabbing:
			_grabbing_with_hand()
			
  
func _shoot_with_equipped_once():
	if equipped == "gun":
		_shooting_with_gun(gun_shoot_bullet_number)
	if equipped == "extinguisher" or equipped == "airhorn":
		_shooting_with_extinguisher()

func _grabbing_with_hand():
	if Gun.get_slide_collision_count() > 0:
		grabbing = true
		grabbed = Gun.get_slide_collision(0).get_collider()
		Gun.find_child("grab_indicator").visible = true
		Gun.velocity = Vector2.ZERO
		grabjoint = PinJoint2D.new()
		grabjoint.global_position = Gun.global_position
		get_tree().current_scene.add_child(grabjoint)
		grabjoint.node_a = self.get_path()
		grabjoint.node_b = Gun.get_path()
		var oldvelocity = linear_velocity
		await get_tree().physics_frame
		var lostvelocity = oldvelocity.length() - linear_velocity.length()
		linear_velocity += linear_velocity.normalized() * lostvelocity

func _ungrab_with_hand():
	if grabjoint != null:
		grabjoint.queue_free()
		grabjoint = null
	Gun.find_child("grab_indicator").visible = false
	grabbing = false
	grabbed = null

func _grab_with_hand_physics():
	var current_grabbed_vel = Vector2.ZERO
	if grabbed is CharacterBody2D:
		current_grabbed_vel = grabbed.velocity
		linear_velocity += current_grabbed_vel - previous_grabbed_vel
		Gun.velocity = current_grabbed_vel
		previous_grabbed_vel = grabbed.velocity
	elif grabbed is RigidBody2D:
		current_grabbed_vel = grabbed.linear_velocity
		linear_velocity += current_grabbed_vel - previous_grabbed_vel
		Gun.velocity = current_grabbed_vel
		previous_grabbed_vel = grabbed.linear_velocity
	var addingvelocity = (Gun.global_position - $Pivot/Gun_pos.global_position) * gun_punch_force * dtime
	apply_central_impulse(addingvelocity)
	
#	if (Gun.global_position - global_position).length() - 10 > gun_move_range:
#		linear_velocity = -linear_velocity

func _shooting_with_extinguisher():
	if oxygen_points > extinguisher_oxygen_cost:
		oxygen_points -= extinguisher_oxygen_cost
		apply_central_impulse((global_position - mousemarker.global_position).normalized() * extinguisher_force)
		var foam = foampart.instantiate()
		foam.global_position = Gun.global_position
		foam.one_shot = true
		if equipped == "airhorn":
			SoundSystem.stop_sound("extinguisher")
			SoundSystem.play_sound("res://sound/airhorn.mp3", "extinguisher", 0.05, Gun.global_position)
		else:
			SoundSystem.play_sound("res://sound/playeronly/extinguisher.mp3", "extinguisher", 0.1, Gun.global_position)
			get_tree().current_scene.add_child(foam)
			while foam != null:
				foam.global_position = Gun.global_position
				var direction = -(global_position - mousemarker.global_position).normalized()
				foam.process_material.direction = Vector3(direction.x, direction.y, 0)
				await get_tree().physics_frame
	

func _shooting_with_gun(number: int):
	if gun_current_ammo <= 0:
		return
	if reloading:
		$Gun_reload.stop()
	gun_current_ammo -= 1
	_go_opposite_of_mouse(gun_shoot_force)
	_camera_shake(0.05, 2.5, 0.5)
	SoundSystem.play_sound("res://sound/playeronly/shotgun shoot.mp3", "shotgun", 0.15, Gun.global_position)
	SoundSystem.stop_sound("", "shotgun reload finished")
	var gun_canon = Gun.find_child("Canon")
	if gun_canon != null:
		for i in number:
			var raycast = RayCast2D.new()
			var line = bullet_trail.new()
			var end_of_ray = Node2D.new()
			raycast.name = "shoot_raycast1"
			raycast.target_position = Vector2(gun_shoot_range, 0)
			randomize()
			raycast.target_position.y += randf_range(-gun_shoot_range * gun_shoot_spread, gun_shoot_range * gun_shoot_spread)
			raycast.collision_mask = $Shoot.collision_mask
			gun_canon.add_child(raycast)
			get_tree().current_scene.add_child(line)
			raycast.add_child(end_of_ray)
			raycast.force_raycast_update()
			if raycast.get_collider() == null:
				raycast.queue_free()
				return
			line.width = 1
			line.add_point(raycast.global_position, 0)
			line.z_index -= 100
			if raycast.is_colliding():
				if not raycast.get_collider().name == "shoot_limit":
					var shoot_part = shoot_particles.instantiate()
					shoot_part.global_position = raycast.get_collision_point()
					shoot_part.process_material.direction = Vector3(raycast.get_collision_normal().x, raycast.get_collision_normal().y, 0)
					shoot_part.one_shot = true
					shoot_part.z_index = -100
					get_tree().current_scene.add_child(shoot_part)
				if raycast.get_collider() is RigidBody2D:
					var dist = raycast.get_collision_point() - raycast.global_position
					raycast.get_collider().apply_central_impulse(dist.normalized() * gun_shoot_force / 5)
				line.add_point(raycast.get_collision_point(), 1)
				if raycast.get_collider() != null:
					if raycast.get_collider().get("health_points") != null:
						raycast.get_collider().set("health_points", raycast.get_collider().get("health_points") - gun_shoot_damage)
			raycast.queue_free()
		var lightex: PointLight2D = Gun.find_child("Shotlight_template")
		if lightex != null:
			var shotlight = PointLight2D.new()
			shotlight.texture = lightex.texture; shotlight.offset = lightex.offset; shotlight.scale = lightex.scale; shotlight.position = lightex.position
			shotlight.rotation = lightex.rotation; shotlight.energy = lightex.energy; shotlight.range_z_min = lightex.range_z_min
			shotlight.color = lightex.color; shotlight.shadow_enabled = true; shotlight.shadow_filter_smooth = lightex.shadow_filter_smooth
			shotlight.shadow_filter = Light2D.SHADOW_FILTER_PCF13; 
			gun_canon.add_child(shotlight)
			while shotlight.energy > 0:
				shotlight.energy -= 30 * dtime
				await get_tree().physics_frame
			shotlight.queue_free()
		
	


func _gun_sprite():
	var Gunsprite = Gun.find_child("gunsprite")
	var airhorn = Gun.find_child("airhorn")
	if abs(Gun.rotation_degrees) > 100:
		Gunsprite.flip_v = true
		airhorn.flip_v = true
	else:
		Gunsprite.flip_v = false
		airhorn.flip_v = false
	
	Gunsprite.visible = false
	$LeftArm/extinguisher.visible = false
	$LeftArm/extinguisher_line.visible = false
	airhorn.visible = false
	
	if equipped == "hand":
		pass
	elif equipped == "gun":
		Gunsprite.visible = true
	elif equipped == "extinguisher":
		$LeftArm/extinguisher.visible = true
		$LeftArm/extinguisher_line.visible = true
	elif equipped == "airhorn":
		airhorn.visible = true
		
		

func _gun_hud():
	if equipped == "gun":
		$HUD/Ammo.visible = true
		if gun_current_ammo <= 0:
			$HUD/Ammo/VBoxContainer/Gauge.visible = false
		else:
			$HUD/Ammo/VBoxContainer/Gauge.visible = true
		if $HUD/Ammo/VBoxContainer/Gauge.get_child_count() != gun_current_ammo:
			for i in $HUD/Ammo/VBoxContainer/Gauge.get_children():
				i.queue_free()
			for k in gun_current_ammo:
				var textrect = TextureRect.new()
				textrect.texture = load("res://Sprites/shotgun_gauge.png")
				$HUD/Ammo/VBoxContainer/Gauge.add_child(textrect)
		
		if reloading:
			$HUD/Ammo/VBoxContainer/ReloadBar.max_value = gun_reload_time
			$HUD/Ammo/VBoxContainer/ReloadBar.value = abs($Gun_reload.time_left - gun_reload_time)
		else:
			$HUD/Ammo/VBoxContainer/ReloadBar.value = 0
	else:
		$HUD/Ammo.visible = false

func _gun_reloading():
	reloading = !$Gun_reload.is_stopped()
	if equipped != "gun":
		$Gun_reload.stop()
		return
	if not reloading:
		if Input.is_action_just_pressed("reload"):
			_start_reload()
	if reloading:
		if $Gun_reload.is_stopped():
			$Gun_reload.start(gun_reload_time)
			$HUD/Ammo/VBoxContainer/Gauge.visible = true
		if gun_current_ammo == gun_max_ammo:
			$Gun_reload.stop()

func _start_reload():
	for i in $HUD/Ammo/VBoxContainer/Gauge.get_children():
		i.queue_free()
	$Gun_reload.start(gun_reload_time)

func _on_gun_reload_timeout():
	gun_current_ammo += 1
	SoundSystem.play_sound("res://sound/playeronly/shotgun reload.mp3", "shotgun", 0.05, Gun.global_position)
	if gun_current_ammo == gun_max_ammo:
		$Gun_reload.stop()
		SoundSystem.play_sound("res://sound/playeronly/shotgun reload finished.mp3", "shotgun", 0.05, Gun.global_position)





func _rotate_camera():
	var cam = get_viewport().get_camera_2d()
	cam.rotation_degrees = lerp(cam.rotation_degrees, -linear_velocity.x/7, 0.01 * dtime)

func _body_movement():
	rleg.global_position = legpos.global_position + Vector2(3, 0)
	lleg.global_position = legpos.global_position - Vector2(3, 0)
#	larm.global_position = armpos.global_position - Vector2(7, 0)
	randomize()
	rleg.rotation = lerp_angle(rleg.rotation, rotation + deg_to_rad(randf_range(-40, 40)), 0.5 * dtime)
	lleg.rotation = lerp_angle(lleg.rotation, rotation + deg_to_rad(randf_range(-40, 40)), 0.5 * dtime)
	larm.rotation = lerp_angle(larm.rotation, rotation + deg_to_rad(22) + deg_to_rad(randf_range(-20, 20)), 0.5 * dtime)
	if Gun != null:
		rarm.look_at(Gun.global_position)
		ramesh.mesh.size.y = (rarm.global_position - Gun.global_position).length()
		ramesh.position.x = 4 + ramesh.mesh.size.y/2 - 5
		
		$LeftArm/extinguisher_line.global_position = ($LeftArm/ext_line_pos.global_position + Gun.global_position)/2
		$LeftArm/extinguisher_line.mesh.size.x = ($LeftArm/extinguisher_line.global_position - Gun.global_position).length()*2
		$LeftArm/extinguisher_line.look_at(Gun.global_position)
	


func _on_visible_on_screen_notifier_2d_screen_exited():
	get_viewport().get_camera_2d().global_position = global_position
	camera_follow_player = true


func _camera_shake(duration: float = 1, shake_size: float = 10, force: float = 0.5):
	var cam = get_viewport().get_camera_2d()
	var timer = get_tree().create_timer(duration)
	while timer.time_left > 0:
		randomize()
		var random_x = randf_range(-shake_size, shake_size)
		var random_y = randf_range(-shake_size, shake_size)
		cam.offset = lerp(cam.offset, Vector2(random_x, random_y), force)
#		cam.offset = Vector2(random_x, random_y)
		await get_tree().physics_frame
	cam.offset = Vector2.ZERO
		
		


func _camera_follow(follow):
	if cam_follow_prev_pos == Vector2.ZERO:
		cam_follow_prev_pos = follow.global_position
	
	var cam = get_viewport().get_camera_2d()
	if not cam_follow_pause:
		cam.global_position = follow.global_position
		cam.zoom = lerp(cam.zoom, cam_follow_zoom, 1 * dtime)
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
#		cam.zoom = lerp(cam.zoom, cam_follow_zoom / 1.5, 1 * dtime)
#		if (cam.global_position - follow.global_position).length() >= 150 or abs(cam.global_position.y - follow.global_position.y) >= 100:
#			cam_follow_pause = false

func _draw_text(text):
	$HUD/Text.visible_characters = 0
	$HUD/Text.text = text
	for i in len(text) + 1:
		$HUD/Text.visible_characters += 1
		await get_tree().create_timer(0.025, false).timeout
	

func _erase_text():
	if $HUD/Text.visible_characters >= len($HUD/Text.text):
		$HUD/Text.text = ""
		$HUD/Text.visible_characters = 0
	else:
		await get_tree().create_timer(2.5, false).timeout
		_erase_text()


func _on_player_area_detector_area_entered(area):
	var areaname = area.get_parent().name
	pass
	


func _on_player_area_detector_area_exited(area):
	var areaname = area.get_parent().name
	pass








func _on_nextweapon_pressed():
	_equip_w_mouse_wheel()

func _on_reload_pressed():
	reloading = !$Gun_reload.is_stopped()
	if equipped != "gun":
		return
	if not reloading:
		_start_reload()

func _on_shoot_pressed():
	shoot_button_pressed = true
	if equipped != "hand":
		_shoot_with_equipped_once()
func _on_shoot_released():
	shoot_button_pressed = false
	if equipped == "hand" and grabbing:
		_ungrab_with_hand()

func _on_pause_pressed():
	$HUD/PauseMenu.pause()
