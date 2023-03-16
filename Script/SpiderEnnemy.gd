extends RigidBody2D
var dtime

@export var enable_ia: bool = true ##false = follow mouse
@export var disable_ia_and_debug: bool = false
@export var max_move_speed_lerp: float = 10000
@export var max_chase_move_speed: float = 275
@export var max_roam_move_speed: float = 75
@export var legs_length: float = 25
@export var legs_width: float = 2
@export var damage: float = 15

@export var max_health: float = 400
@export var legs_max_health: float = 10
@export var percentage_damage_per_leg_destroyed: float = 0.15 #1 = 100%

@export var target_desired_dist: float = 30
@export var path_desired_dist: float = 15

@onready var Body: MeshInstance2D = $BodyPivot/Body

@onready var Legs: Node2D = $Legs

@onready var legraycast: RayCast2D = $Legs/leg1/legraycast

@onready var Collisionshape: CollisionShape2D = $CollisionShape2D
@onready var Normalcolmask: CharacterBody2D = $NodesForCollisionMask/NormalCol
@onready var Grabbedcolmask: CharacterBody2D = $NodesForCollisionMask/GrabbedCol
@onready var EyeLight: PointLight2D = find_child("EyeLight")

var health_points: float = 300

var move_speed_lerp: float = 10000  #unused
var chase_move_speed: float = 200
var roam_move_speed: float = 100
var max_legs: int = 8

var headlegs = []
var middlefrontlegs = []
var legsnormalpos = {}
var legsblocked = {}
var legsgoingtoblockedpos = []
var legblockedto = Vector2.ZERO

var Player: RigidBody2D = null

var was_reached_before: bool = false

var found_player: bool = false
var reached: bool = false
var custom_reached: bool = false
var chasing: bool = false

var eyes_blink_awaiting: bool = false

var spawn_position: Vector2 = Vector2.ZERO

func _ready():
	spawn_position = global_position
	
	move_speed_lerp = max_move_speed_lerp
	chase_move_speed = max_chase_move_speed
	roam_move_speed = max_roam_move_speed
	health_points = max_health
	gravity_scale = 0
	
	var half_legs = Legs.get_child_count() / 2
	var leg_count = 1
	max_legs = 0
	for i in Legs.get_children():
		if leg_count <= half_legs:
			_setup_leg(i, false, leg_count)
		else:
			_setup_leg(i, true, leg_count)
		leg_count += 1
		max_legs += 1

func _setup_leg(kinematicleg: Marker2D, scnd_half: bool = false, leg_count: int = 1):
	var legpivot1: Node2D = kinematicleg.find_child("LegPivot1")
	var legpivot2: Node2D = kinematicleg.find_child("LegPivot2")
	var leg1: MeshInstance2D = legpivot1.find_child("MeshInstance2D")
	var leg2: MeshInstance2D = legpivot2.find_child("MeshInstance2D2")
	var legraycast: RayCast2D = kinematicleg.find_child("legraycast")
	var idle_pos: Marker2D = Marker2D.new()
	
	legpivot1.visible = true
	legpivot2.visible = true
	if kinematicleg.name == "leg" + str(Legs.get_child_count()/2 + 1) or kinematicleg.name == "leg1":
		headlegs.append(kinematicleg)
	if kinematicleg.name == "leg" + str(Legs.get_child_count()/2 + 2) or kinematicleg.name == "leg2":
		middlefrontlegs.append(kinematicleg)

func _custom_target_reached():
	if $NavigationAgent2D.distance_to_target() <= $NavigationAgent2D.target_desired_distance:
		return true
	else:
		return false

func _physics_process(delta):
	dtime = delta
	
	if disable_ia_and_debug:
		_debug()
		return
	if health_points <= 0:
		queue_free()
		
	
	custom_reached = _custom_target_reached()
	reached = false
	if enable_ia:
		_ia_system()
	else:
		_follow_mouse()
	
	if reached:
#		_set_velocity(Player.linear_velocity)
		if chasing:
			apply_central_impulse((Player.linear_velocity - linear_velocity) * 150 * dtime)
			_prepare_kinematic_leg(true)
			_damage(Player)
		else:
			_prepare_kinematic_leg(false)
		if not was_reached_before:
			was_reached_before = true
			$NavigationAgent2D.target_desired_distance = target_desired_dist * 1.5
			collision_layer = Grabbedcolmask.collision_layer
			collision_mask = Grabbedcolmask.collision_mask
	else:
		_prepare_kinematic_leg(false)
		$NavigationAgent2D.target_desired_distance = target_desired_dist
		if was_reached_before:
			was_reached_before = false
			collision_layer = Normalcolmask.collision_layer
			collision_mask = Normalcolmask.collision_mask
			legsblocked = {}
	
	
	if not found_player and Player != null:
		$FindPlayerCast.look_at(Player.global_position)
		if $FindPlayerCast.is_colliding():
			if "Player" in $FindPlayerCast.get_collider().name:
				found_player = true
	
	_body_movement()
	$NavigationAgent2D.set_velocity(linear_velocity)

func _ia_system():
	if Player != null:
		if found_player:
			if not $NavigationAgent2D.is_target_reached():
				$NavigationAgent2D.path_desired_distance = path_desired_dist
				$NavigationAgent2D.set_target_position(Player.global_position)
				_go_to_next_point(chase_move_speed, max_chase_move_speed)
				reached = false
				chasing = true
			else:
				$NavigationAgent2D.set_target_position(Player.global_position)
				reached = true
				chasing = true
		else:
			chasing = false
			_random_roaming()
	else:
		Player = get_tree().current_scene.find_child("Player", true, false)

func _random_roaming():
	if custom_reached or $NavigationAgent2D.target_position == Vector2.ZERO:
		_get_next_random_roam_point()
	else:
		if not $NavigationAgent2D.is_target_reachable():
			_get_next_random_roam_point()
			return
		else:
#			$NavigationAgent2D.target_desired_distance = target_desired_dist * 2.5
#			$NavigationAgent2D.path_desired_distance = path_desired_dist * 3
			_go_to_next_point(roam_move_speed, max_roam_move_speed)
			if custom_reached:
				_get_next_random_roam_point()

func _get_next_random_roam_point():
	var next_roam_point: Vector2 = Vector2.ZERO
	var roam_radius: float = 150
	var max_rad: Vector2 = Vector2(spawn_position.x + roam_radius, spawn_position.y + roam_radius)
	var min_rad: Vector2 = Vector2(spawn_position.x - roam_radius, spawn_position.y - roam_radius)
	next_roam_point = Vector2(randf_range(min_rad.x, max_rad.x), randf_range(min_rad.y, max_rad.y))
	$NavigationAgent2D.set_target_position(next_roam_point)

func _set_velocity(velocity: Vector2 = Vector2.ZERO):
	linear_velocity = velocity

func _lerp_velocity(velocity: Vector2 = Vector2.ZERO, force: float = 1):
	linear_velocity = lerp(linear_velocity, velocity, force * dtime)

func _follow_mouse():
	_set_velocity(get_global_mouse_position() - global_position)
	_body_movement()

func _go_to_next_point(speed: float, max_speed: float):
	var dist: Vector2 = global_position - $NavigationAgent2D.get_next_path_position()
	var dist_norm: Vector2 = dist.normalized()
	var impulse_velocity: Vector2 = speed * -dist_norm * 60
#	impulse_velocity = _acceleration_boost(impulse_velocity, dist_norm)
	impulse_velocity = _check_next_impulse_clamp(impulse_velocity, speed, 60)
	apply_central_impulse(impulse_velocity * dtime)
	_check_and_brake(1000)

func _check_next_impulse_clamp(impulse_velocity: Vector2, speed: float, decomposer: float):
	var abs_vel = abs(linear_velocity)
	var decomposed_impulse = impulse_velocity / decomposer * dtime
	
	if abs(linear_velocity.x + decomposed_impulse.x) > speed:
		if abs(linear_velocity.x) < abs(linear_velocity.x + decomposed_impulse.x):
			impulse_velocity.x = 0
	
	if abs(linear_velocity.y + decomposed_impulse.y) > speed:
		if abs(linear_velocity.y) < abs(linear_velocity.y + decomposed_impulse.y):
			impulse_velocity.y = 0
	
	return impulse_velocity

func _get_to_next_path_pos(speed: float, max_speed: float):
	if $NavigationAgent2D.get_next_path_position() != Vector2.ZERO:
		var dist: Vector2 = global_position - $NavigationAgent2D.get_next_path_position()
		var dist_norm: Vector2 = dist.normalized()
		var lerp_next_velocity = lerp(linear_velocity, speed * -dist_norm, 0.75)
		lerp_next_velocity = _acceleration_boost(lerp_next_velocity * 60 * dtime, dist_norm)
		lerp_next_velocity = _check_next_velocity_clamp(lerp_next_velocity, speed, max_speed)
		apply_central_impulse(lerp_next_velocity * 60 * dtime)
		_check_and_brake()

func _acceleration_boost(next_vel, next_path_norm):
	var boost_speed = 100
	if next_vel.length() < 100:
		next_vel += boost_speed * next_path_norm * dtime
	return next_vel

func _check_next_velocity_clamp(next_vel: Vector2, speed: float, max_speed: float):
	if abs(linear_velocity.x + next_vel.x) > max_speed:
		next_vel.x = (linear_velocity.x + next_vel.x) - speed * sign(next_vel.x)
	if abs(linear_velocity.y + next_vel.x) > max_speed:
		next_vel.y = (linear_velocity.y + next_vel.y) - speed * sign(next_vel.x)
	return next_vel

func _check_and_brake(BrakeForce: float = 1000):
	var old_vel: Vector2 = linear_velocity
	var abs_old_vel: Vector2 = abs(old_vel)
	await get_tree().physics_frame
	var abs_vel: Vector2 = abs(linear_velocity)
	var sign_vel: Vector2 = sign(linear_velocity)
	if abs_old_vel.x > abs_vel.x:
		linear_velocity.x -= BrakeForce * sign_vel.x * dtime * (max_legs / Legs.get_child_count())
	if abs_old_vel.y > abs_vel.y:
		linear_velocity.y -= BrakeForce * sign_vel.y * dtime * (max_legs / Legs.get_child_count())

func _damage(entitie):
	if entitie.has_method("get_damaged"):
		entitie.get_damaged(damage * dtime, false)
	elif entitie.get("health_points") != null:
		entitie.set("health_points", entitie.get("health_points") - damage * dtime)

func _body_movement():
	if not is_zero_approx(linear_velocity.length()):
		var spider_front = global_position + Vector2(10, 10) * linear_velocity.normalized()
#		$Look_at_destination.look_at($NavigationAgent2D.get_next_path_position())
		$Look_at_destination.look_at(spider_front)
		var look_at_rotation = $Look_at_destination.rotation + deg_to_rad(180)
		Body.rotation = lerp_angle(Body.rotation, look_at_rotation, 7 * dtime)
		
		var angle_to = rad_to_deg(Body.get_angle_to(spider_front)) + 90
		
		Legs.rotation = Body.rotation
		$CollisionShape2D.rotation = Body.rotation + deg_to_rad(90)
		
		_eyes_blink()
		_eyes_light()

func _eyes_blink():
	if not eyes_blink_awaiting:
		eyes_blink_awaiting = true
		var eyes_number = $BodyPivot/Body/Eyes.get_child_count()
		var eyes_speed = 5
		while true:
			var eyes_finished: int = 0
			for i in $BodyPivot/Body/Eyes.get_children():
				if i.scale.y <= 0.1:
					eyes_finished += 1
				else:
					i.scale.y = lerpf(i.scale.y, 0, eyes_speed * dtime)
			if eyes_finished == eyes_number:
				break
			await get_tree().physics_frame
		await get_tree().create_timer(0.1, false)
		while true:
			var eyes_finished: int = 0
			for i in $BodyPivot/Body/Eyes.get_children():
				if is_equal_approx(i.scale.y, 1):
					eyes_finished += 1
				else:
					i.scale.y = lerpf(i.scale.y, 1, eyes_speed * dtime)
			if eyes_finished == eyes_number:
				break
			await get_tree().physics_frame
		await get_tree().create_timer(6, false)
		eyes_blink_awaiting = false

func _eyes_light():
	if chasing:
		EyeLight.scale = lerp(EyeLight.scale, Vector2(0.07, 0.05), 3 * dtime)
		EyeLight.energy = lerp(EyeLight.energy, 1.5, 3 * dtime)
	else:
		EyeLight.scale = lerp(EyeLight.scale, Vector2(0.04, 0.04), 3 * dtime)
		EyeLight.energy = lerp(EyeLight.energy, 1.0, 3 * dtime)

func _prepare_kinematic_leg(attached_to_player: bool = false):
	var half_legs = Legs.get_child_count() / 2
	var leg_count = 1
	for i in Legs.get_children():
		if leg_count <= half_legs:
			_kinematic_leg(i, false, attached_to_player)
		else:
			_kinematic_leg(i, true, attached_to_player)
		leg_count += 1

func _kinematic_leg(kinematicleg: Marker2D, first_half: bool = false, attached_to_player: bool = false):
	var legpivot1: Node2D = kinematicleg.find_child("LegPivot1")
	var legpivot2: Node2D = kinematicleg.find_child("LegPivot2")
	var leg1: MeshInstance2D = legpivot1.find_child("MeshInstance2D")
	var leg2: MeshInstance2D = legpivot2.find_child("MeshInstance2D2")
	var legraycast: RayCast2D = kinematicleg.find_child("legraycast")
	var anglediffgeter: Node2D = kinematicleg.find_child("anglehaver")
	var idle_pos: Marker2D = kinematicleg.find_child("Idle")
#	var idle_pos: Marker2D = legsnormalpos[kinematicleg.name]
	
	var testcircle1 = legpivot1.find_child("testcircle")
	var testcircle2 = legpivot2.find_child("testcircle2")
	
	
	if testcircle1.mesh.radius != 20:
		testcircle1.mesh.radius = 20; testcircle1.mesh.height = 40
		testcircle2.mesh.radius = 20; testcircle2.mesh.height = 40
		_set_mesh_length_and_width([leg1, leg2])
	
	leg1.position.x = leg1.mesh.size.x/2
	leg2.position.x = leg2.mesh.size.x/2
	var bod = Body.self_modulate
	leg1.modulate = Color(bod.r/3, bod.g/3, bod.b/3, bod.a)
	leg2.modulate = Color(bod.r/2, bod.g/2, bod.b/2, bod.a)
	
	legraycast.target_position.y = -leg1.mesh.size.x * 2
	legraycast.force_raycast_update()
	
	var legdistance_before_calc = (legpivot1.global_position - legpivot2.global_position).length()
	var og_legsize = leg1.mesh.size.x
	
	if attached_to_player and legdistance_before_calc < og_legsize*2:   #if attached to the player
		legsblocked[kinematicleg] = Player.global_position
		_leg_going_to_blocked_position(kinematicleg, 10)
	elif not kinematicleg in legsblocked and legraycast.is_colliding():    #if legs not attached to anything but raycast is colliding
		legblockedto = legraycast.get_collision_point()
		legsblocked[kinematicleg] = legraycast.get_collision_point()
		leg1.mesh.size.x = legs_length
		leg2.mesh.size.x = legs_length
	elif kinematicleg in legsblocked and not kinematicleg in legsgoingtoblockedpos:    #if legs are completely attached
		_leg_going_to_blocked_position(kinematicleg, 20)
	elif kinematicleg in legsblocked and kinematicleg in legsgoingtoblockedpos:    #if legs are attached but not in place rn
		_leg_going_to_blocked_position(kinematicleg, 10)
	else:                                                                        #if legs not attached at all
		legpivot2.global_position = lerp(legpivot2.global_position, idle_pos.global_position, 5 * dtime)
	
	$MARKER.global_position = legpivot2.global_position
	anglediffgeter.global_position = legpivot2.global_position
	anglediffgeter.look_at(legpivot1.global_position)
	anglediffgeter.rotation_degrees -= 90
	
	var anglediff = anglediffgeter.rotation
	var legdistance = (legpivot1.global_position - legpivot2.global_position).length() 
	var legsize = leg1.mesh.size.x
	
	if first_half and not attached_to_player or not first_half and attached_to_player:
		legpivot2.rotation = asin((legdistance/2)/legsize) + anglediff
		legpivot1.rotation = -asin((legdistance/2)/legsize) + anglediff
	elif not first_half and not attached_to_player or first_half and attached_to_player:
		legpivot2.rotation = -asin((legdistance/2)/legsize) + anglediff + deg_to_rad(180)
		legpivot1.rotation = asin((legdistance/2)/legsize) + anglediff + deg_to_rad(180)
	
	if kinematicleg in legsblocked:
		legdistance = (legpivot1.global_position - legpivot2.global_position).length()
		legsize = leg1.mesh.size.x
		if legdistance > legsize*2:
			_reset_kinematic(kinematicleg, legraycast)

func _reset_kinematic(kinematicleg: Marker2D, legraycast: RayCast2D):
	if not legraycast.is_colliding():
		legsblocked.erase(kinematicleg)
		legsgoingtoblockedpos.erase(kinematicleg)
	else:
		legsblocked[kinematicleg] = legraycast.get_collision_point()
		legsgoingtoblockedpos.append(kinematicleg)

func _leg_going_to_blocked_position(kinematicleg: Marker2D, lerp: float):
	var legpivot2: Node2D = kinematicleg.find_child("LegPivot2")
	
	legpivot2.global_position = lerp(legpivot2.global_position, legsblocked[kinematicleg], lerp * dtime)
	if (legpivot2.global_position - legsblocked[kinematicleg]).length() < 10:
		legsgoingtoblockedpos.erase(kinematicleg)

func _set_mesh_length_and_width(mesh: Array):
	for i in mesh:
		i.mesh.size.x = legs_length
		i.mesh.size.y = legs_width

func lost_a_leg():
	move_speed_lerp -= max_move_speed_lerp / max_legs 
	chase_move_speed -= max_chase_move_speed / max_legs

func _debug():
	_prepare_kinematic_leg(false)
	_body_movement()
	if $NavigationAgent2D.target_position == Vector2.ZERO or ($NavigationAgent2D.get_next_path_position() - global_position).length() > 20 + $NavigationAgent2D.path_desired_distance:
		$NavigationAgent2D.path_desired_distance = path_desired_dist
		$NavigationAgent2D.target_desired_distance = target_desired_dist
		$NavigationAgent2D.target_position = get_tree().current_scene.find_child("spider_debug").global_position
	if not $NavigationAgent2D.is_target_reached():
#		_go_to_next_point(roam_move_speed, max_roam_move_speed)
		_go_to_next_point(chase_move_speed, max_chase_move_speed)
