extends RigidBody2D
var dtime

@export var enable_ia: bool = true ##false = follow mouse
@export var max_move_speed_lerp: float = 10000
@export var max_move_speed: float = 400
@export var legs_length: float = 25
@export var legs_width: float = 2
@export var damage: float = 35
@export var max_health: float = 400

@onready var Body: MeshInstance2D = $Body

@onready var Legs: Node2D = $Legs

@onready var legraycast: RayCast2D = $Legs/leg1/legraycast

@onready var Collisionshape: CollisionShape2D = $CollisionShape2D
@onready var Normalcolmask: CharacterBody2D = $NodesForCollisionMask/NormalCol
@onready var Grabbedcolmask: CharacterBody2D = $NodesForCollisionMask/GrabbedCol

var health_points: float = 300

var move_speed_lerp: float = 10000
var move_speed: float = 200
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

func _ready():
	move_speed_lerp = max_move_speed_lerp
	move_speed = max_move_speed
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

func _physics_process(delta):
	dtime = delta
	if health_points <= 0:
		queue_free()
	
	reached = false
	if enable_ia:
		if Player != null and found_player:
			if not $NavigationAgent2D.is_target_reached():
				$NavigationAgent2D.set_target_position(Player.global_position)
				_get_to_next_path_pos()
				reached = false
			else:
				$NavigationAgent2D.set_target_position(Player.global_position)
				reached = true
		else:
			Player = get_tree().current_scene.find_child("Player", true, false)
	else:
		_follow_mouse()
	
	if reached:
#		_set_velocity(Player.linear_velocity)
		apply_central_impulse((Player.linear_velocity - linear_velocity) * 150 * dtime)
		_prepare_kinematic_leg(true)
		_damage(Player)
		if not was_reached_before:
			was_reached_before = true
			$NavigationAgent2D.target_desired_distance *= 1.5
			collision_layer = Grabbedcolmask.collision_layer
			collision_mask = Grabbedcolmask.collision_mask
	else:
		_prepare_kinematic_leg(false)
		if was_reached_before:
			was_reached_before = false
			$NavigationAgent2D.target_desired_distance /= 1.5
			collision_layer = Normalcolmask.collision_layer
			collision_mask = Normalcolmask.collision_mask
			legsblocked = {}
	
	
	if not found_player:
		for i in $ShapeCast2D.get_collision_count():
			if "Player" in $ShapeCast2D.get_collider(i).name:
				found_player = true
	
	_body_movement()
	$NavigationAgent2D.set_velocity(linear_velocity)

func _set_velocity(velocity: Vector2 = Vector2.ZERO):
	linear_velocity = velocity

func _lerp_velocity(velocity: Vector2 = Vector2.ZERO, force: float = 1):
	linear_velocity = lerp(linear_velocity, velocity, force * dtime)

func _follow_mouse():
	_set_velocity(get_global_mouse_position() - global_position)
	_body_movement()

func _get_to_next_path_pos():
	if $NavigationAgent2D.get_next_path_position() != Vector2.ZERO:
		var dist: Vector2 = global_position - $NavigationAgent2D.get_next_path_position()
		var dist_norm: Vector2 = dist.normalized()
		var lerp_next_velocity = lerp(linear_velocity, move_speed * -dist_norm, 0.75)
#		_set_velocity((move_speed * -dist_norm) * dtime)
#		apply_central_impulse((move_speed * -dist_norm) * 30 * dtime)
		lerp_next_velocity = _acceleration_boost(lerp_next_velocity * 60 * dtime, dist_norm)
		lerp_next_velocity = _check_next_velocity_clamp(lerp_next_velocity)
		apply_central_impulse(lerp_next_velocity * 60 * dtime)
		_check_and_brake()

func _acceleration_boost(next_vel, next_path_norm):
	var boost_speed = 100
	if next_vel.length() < 100:
		next_vel += boost_speed * next_path_norm * dtime
	return next_vel

func _check_next_velocity_clamp(next_vel):
	if abs(linear_velocity.x + next_vel.x) > max_move_speed:
		next_vel.x = (linear_velocity.x + next_vel.x) - move_speed * sign(next_vel.x)
	if abs(linear_velocity.y + next_vel.x) > max_move_speed:
		next_vel.y = (linear_velocity.y + next_vel.y) - move_speed * sign(next_vel.x)
	return next_vel

func _check_and_brake():
	var old_vel: Vector2 = linear_velocity
	var abs_old_vel: Vector2 = abs(old_vel)
	await get_tree().physics_frame
	var abs_vel: Vector2 = abs(linear_velocity)
	var sign_vel: Vector2 = sign(linear_velocity)
	if abs_old_vel.x > abs_vel.x:
		linear_velocity.x -= 200 * sign_vel.x * dtime * (max_legs / Legs.get_child_count())
	if abs_old_vel.y > abs_vel.y:
		linear_velocity.y -= 200 * sign_vel.y * dtime * (max_legs / Legs.get_child_count())

func _damage(entitie):
	if entitie.get("health_points") != null:
		entitie.set("health_points", entitie.get("health_points") - damage * dtime)

func _body_movement():
	if not is_zero_approx(linear_velocity.length()):
		var spider_front = global_position + Vector2(10, 10) * linear_velocity.normalized()
#		$Look_at_destination.look_at($NavigationAgent2D.get_next_path_position())
		$Look_at_destination.look_at(spider_front)
		var look_at_rotation = $Look_at_destination.rotation_degrees + 90
		Body.rotation_degrees = lerp(Body.rotation_degrees, look_at_rotation, 3 * dtime)
		Legs.rotation = Body.rotation + deg_to_rad(90)
		$CollisionShape2D.rotation = Body.rotation

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
	else:   #if legs not attached at all
		legpivot2.global_position = lerp(legpivot2.global_position, idle_pos.global_position, 5 * dtime)
		pass
	
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
#		if kinematicleg in headlegs:
#			if legpivot2.position.y > 15:
#				_reset_kinematic(kinematicleg, legraycast)

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
	move_speed -= max_move_speed / max_legs
