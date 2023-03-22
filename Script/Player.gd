extends RigidBody2D
var shoot_particles = preload("res://Particles/shot_particles.tscn")
var bullet_trail = preload("res://Particles/Bullet_trails.gd")
var shoot_limit = preload("res://Entities/shoot_limit.tscn")
var gun_spawn = preload("res://Entities/player_gun.tscn")
var dpart = preload("res://Entities/death_part.tscn")
var foampart = preload("res://Particles/cloudparticles.tscn")
var bloodpart = preload("res://Particles/blood_particles.tscn")
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

var damage_before_blood: float = 1
var node_bin: Array = []   #instantiated nodes that should be deleted when .queue_free()

var Gun: CharacterBody2D
var gun_lim: CharacterBody2D
var gun_reload_hud_tween: Tween
var old_gun_vel: Vector2 = Vector2.ZERO #BEFORE IMPACT
var test_marker: MeshInstance2D = null
var grabjoint: PinJoint2D = null

var already_collided_point = [] #for _collision_particles()

@onready var rleg: Node2D = $RightLeg
@onready var lleg: Node2D = $LeftLeg
@onready var legpos: Marker2D = $Legspos
@onready var armpos: Marker2D = $Armpos
@onready var larm: Node2D = $LeftArm
@onready var rarm: Node2D = $RightArm
@onready var ramesh: MeshInstance2D = $RightArm/MeshInstance2D
@onready var mousemarker: Marker2D = $MousePivot/MouseMarker

var camera: Camera2D

var cursor_position: Vector2 = Vector2.ZERO

var chromaticabb_timer: SceneTreeTimer
var chroma_ennemi_list: Dictionary = {
	"BasicRebel": {"lerp": false, "value": 0.05, "force": 0, "timer": 0},
	"Spider": {"lerp": true, "value": 0.1, "force": 1.5, "timer": 1},
}

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
	
	camera = get_viewport().get_camera_2d()

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
		mousemarker.visible = false
	elif mobile_control_mode == "Cursor":
		_custom_mouse_velocity() #move the cursor with finger
		mousemarker.visible = true

func _physics_process(delta):
	dtime = delta
	SoundSystem.space_audio = in_space
	
	if camera == null:
		camera = get_viewport().get_camera_2d()
	
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
	_space_sound()
	_health_hud()
	_health_regen()
	_body_movement() #visual only
	_shaders()
	_collision_particles()
	if camera_follow_player and get_viewport().get_camera_2d() != null:
		camera.follow(self)
	
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

func get_damaged(damage: float, once: bool = true, from = null):
	health_points -= damage
	
	if from != null:
		for i in chroma_ennemi_list:
			if i in from.name:
				var dic = chroma_ennemi_list[i]
				_chromatic_abberation(dic.lerp, dic.value, dic.force, dic.timer)
	
	
	if not once:
		damage_before_blood -= damage
		if damage_before_blood <= 0:
			damage_before_blood = 1.0
			var blood = bloodpart.instantiate()
			blood.global_position = global_position
			blood.one_shot = true
			blood.amount = 1
			get_tree().current_scene.add_child(blood)
			node_bin.append(blood)
			await get_tree().create_timer(blood.lifetime + 1, false).timeout
			blood.queue_free()
	else:
		var blood = bloodpart.instantiate()
		blood.global_position = global_position
		blood.one_shot = true
		blood.amount = damage
		get_tree().current_scene.add_child(blood)
		node_bin.append(blood)
		await get_tree().create_timer(blood.lifetime + 1, false).timeout
		blood.queue_free()

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
		for i in node_bin:
			if i != null:
				i.queue_free()
		queue_free()

func _oxygen():
	if oxygen_points <= 0:
		health_points -= 20 * dtime
	if oxygen_points < 100:
		$HUD/Oxygen.visible = true
	else:
		$HUD/Oxygen.visible = false
	$HUD/Oxygen.value = oxygen_points
	$HUD/Oxygen.visible = false          #DISABLE OXYGEN HUD
	
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
	if camera:
		camera.camera_shake(0.2, 2.5, 0.5)
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
			await get_tree().physics_frame
			await get_tree().physics_frame
		_gun_shoot_light_flash()
		_muzzleflash_on_gun()

func _gun_shoot_light_flash():
	var lightex: PointLight2D = Gun.find_child("Shotlight_template")
	if lightex != null:
		var shotlight = PointLight2D.new()
		var arealight = PointLight2D.new()
		shotlight.texture = lightex.texture; shotlight.offset = lightex.offset; shotlight.scale = lightex.scale; shotlight.global_position = lightex.global_position
		shotlight.rotation = Gun.rotation - deg_to_rad(90); shotlight.energy = lightex.energy; shotlight.range_z_min = lightex.range_z_min
		shotlight.color = lightex.color; shotlight.shadow_enabled = true; shotlight.shadow_filter_smooth = lightex.shadow_filter_smooth
		shotlight.shadow_filter = Light2D.SHADOW_FILTER_PCF13; 
		get_tree().current_scene.add_child(shotlight)
		arealight.texture = load("res://Sprites/light/light_round.png")
		arealight.range_z_min = lightex.range_z_min; arealight.global_position = Gun.global_position; arealight.color = lightex.color
		arealight.shadow_enabled = true; arealight.shadow_filter_smooth = lightex.shadow_filter_smooth; arealight.energy = 0.75
		arealight.scale = Vector2(4, 4)
		get_tree().current_scene.add_child(arealight)
		var timer_await = get_tree().create_timer(5, false)
		node_bin.append(shotlight)
		node_bin.append(arealight)
		while timer_await.time_left > 0:
			if shotlight.energy > 0: shotlight.energy -= 20 * dtime
			else: shotlight.energy = 0
			if arealight.energy > 0: arealight.energy -= 2 * dtime
			else: arealight.energy = 0
			await get_tree().physics_frame
		shotlight.queue_free()
		arealight.queue_free()

func _muzzleflash_on_gun():
	var muzzleflash = Gun.find_child("MuzzleFlash")
	muzzleflash.visible = true
	await get_tree().create_timer(0.07, false).timeout
	muzzleflash.visible = false

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
	
	if Input.is_action_just_pressed("flashlight"):
		$Lights/ForeheadLight.enabled = !$Lights/ForeheadLight.enabled
		$Lights/ForeheadLight.visible = $Lights/ForeheadLight.enabled
	$Lights/ForeheadLight.look_at(get_global_mouse_position())
	$Lights/ForeheadLight.rotation_degrees -= 90

func _collision_particles():  #spawn particles when you collide with a wall
	var get_collision = move_and_collide(linear_velocity/50, true)
	var speed_min_spawnpart = 25
	if linear_velocity.length() >= speed_min_spawnpart:
		if get_collision:
			var collid_pos = get_collision.get_position()
			var raycast = find_child("WallDetector")
			raycast.global_position = global_position
			raycast.look_at(collid_pos)
			raycast.force_raycast_update()
			var collid_norm = raycast.get_collision_normal()
			
			if already_collided_point.size() > 0: #verif pour qu'il n'en y ai pas pleins au même endroit
				for k in already_collided_point:
					var diff = collid_pos - k
					var difflen = diff.length()
					var treshold = 15
					if difflen < treshold:
						return
			already_collided_point.append(collid_pos)
			
			var collparts_spawned = []
			for i in range(1, 3):  #pour qu'il y ait 2 particules de sens opposé
				var collpart = load("res://Particles/wall_dust.tscn").instantiate()
				collpart.modulate.a *= 0.15
				collpart.global_position = collid_pos
				collpart.one_shot = true
				
				var medium_speed = 150
				var speed = linear_velocity.length()
				var normal_max_velocity = collpart.process_material.initial_velocity_max
				if speed > medium_speed:
					collpart.process_material.initial_velocity_min *= 1
					collpart.process_material.initial_velocity_max *= 1.25
				
				if i == 1:
					collpart.process_material.direction = Vector3(collid_norm.y, collid_norm.x, 0)
				elif i == 2:
					collpart.process_material.direction = Vector3(-collid_norm.y, -collid_norm.x, 0)
				get_tree().current_scene.add_child(collpart)
				collparts_spawned.append(collpart)
				node_bin.append(collpart)
				await get_tree().physics_frame
				
				collpart.process_material.initial_velocity_max = normal_max_velocity
			
			_collision_sound()
			await get_tree().create_timer(1, false).timeout
			already_collided_point.pop_at(0)
			
			await get_tree().create_timer(3, false).timeout
			for i in collparts_spawned:
				i.queue_free()

func _collision_sound(): #go check _collision_particles()
	var speed = linear_velocity.length()
	var soft_sound_speed = 100
	var medium_sound_speed = 150 #after that is hard sound speed :) 
	var all_soft_hit_sound = [
#		"res://sound/hitwall/hitwall1.mp3",
		"res://sound/hitwall/hitwall2.mp3",
		"res://sound/hitwall/hitwall3.mp3",
		"res://sound/hitwall/hitwall4.mp3",
	]
	var all_medium_hit_sound = [
		"res://sound/hitwall/punch-boxing-02wav-14897.mp3",
		"res://sound/hitwall/punch-boxing-05-reverb-102915.mp3",
		"res://sound/hitwall/punch-boxing-06-reverb-82202.mp3",
	]
	var random_sound: String
	var added_db: float
	if speed < soft_sound_speed:
		random_sound = all_soft_hit_sound.pick_random()
		added_db = -15
	elif speed < medium_sound_speed:
		random_sound = all_medium_hit_sound.pick_random()
		added_db = -10
	else:
		random_sound = all_medium_hit_sound.pick_random()
		added_db = -2
	SoundSystem.play_sound(random_sound, "hitwall", 0.4, global_position, added_db)

func _chromatic_abberation(lerp: bool = true, value: float = 0.01, force: float = 1, timer: float = 0):
	var chromaticabb_value = find_child("ChromaticAbberation").material.get_shader_parameter("spread")
	if lerp:
		chromaticabb_value = lerp(chromaticabb_value, value, force * dtime)
	else:
		chromaticabb_value = value
	find_child("ChromaticAbberation").material.set_shader_parameter("spread", chromaticabb_value)
	
	if not chromaticabb_timer:
		chromaticabb_timer = get_tree().create_timer(timer)
	
	if timer >= chromaticabb_timer.time_left:
		chromaticabb_timer = get_tree().create_timer(timer)

func _oxygen_tank():
	var progress = (max_oxygen - oxygen_points) / (max_oxygen - 0) * (1 - 0)
	$Mesh/OxygenBottle.material.set_shader_parameter("progress", 1 - progress)

func _shaders():
	if chromaticabb_timer == null or chromaticabb_timer.time_left <= 0:
		_chromatic_abberation(true, 0.01, 2, 0)
	_oxygen_tank()

func _space_sound():
	if in_space:
		if oxygen_points < 0:
			SoundSystem.stop_sound("playerbreathing")
		elif oxygen_points < 30:
			if not SoundSystem.is_playing("res://sound/playeronly/breathing faster in helmet.mp3"):
				SoundSystem.stop_sound("playerbreathing")
				SoundSystem.play_sound("res://sound/playeronly/breathing faster in helmet.mp3", "playerbreathing", 0, Vector2.ZERO, 3)
		else:
			if not SoundSystem.is_playing("res://sound/playeronly/breathing in helmet.mp3"):
				SoundSystem.stop_sound("playerbreathing")
				SoundSystem.play_sound("res://sound/playeronly/breathing in helmet.mp3", "playerbreathing", 0, Vector2.ZERO, 10)
	else:
		SoundSystem.stop_sound("playerbreathing")

func _on_visible_on_screen_notifier_2d_screen_exited():
	get_viewport().get_camera_2d().global_position = global_position
	camera_follow_player = true



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

#####MOBILE FUNCTION#####
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
	PauseMenu.pause()
########################
