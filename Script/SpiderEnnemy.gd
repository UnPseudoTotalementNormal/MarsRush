extends CharacterBody2D
var dtime

@export var legs_length: float = 20
@export var legs_width: float = 2

@onready var Body: MeshInstance2D = $Body

@onready var Legs: Node2D = $Legs

@onready var legraycast: RayCast2D = $Legs/leg1/legraycast


var headlegs = []
var legsnormalpos = {}
var legsblocked = {}
var legsgoingtoblockedpos = []
var legblockedto = Vector2.ZERO

func _ready():
	var half_legs = Legs.get_child_count() / 2
	var leg_count = 1
	for i in Legs.get_children():
		if leg_count <= half_legs:
			_setup_leg(i, false, leg_count)
		else:
			_setup_leg(i, true, leg_count)
		leg_count += 1

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

func _physics_process(delta):
	dtime = delta
#	for i in legsnormalpos:
#		printt(i, legsnormalpos[i].global_position)
	var half_legs = Legs.get_child_count() / 2
	var leg_count = 1
	for i in Legs.get_children():
		if leg_count <= half_legs:
			_kinematic_leg(i, false)
		else:
			_kinematic_leg(i, true)
		leg_count += 1
	
	Body.look_at(global_position + Vector2(10, 10) * velocity.normalized())
	Legs.rotation = Body.rotation
	Body.rotation_degrees += 90
	Legs.rotation_degrees += 180
	
	velocity =  get_global_mouse_position() - global_position
	move_and_slide()



func _kinematic_leg(kinematicleg: Marker2D, first_half: bool = false):
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
	leg1.modulate = Color.BLACK
	leg2.modulate = Color.BLACK
	
	legraycast.target_position.y = -leg1.mesh.size.x * 2
#	legraycast.look_at(global_position + Vector2(10, 10) * velocity.normalized())
	legraycast.force_raycast_update()
	
	var legdistance_before_calc = (legpivot1.global_position - legpivot2.global_position).length()
	
	if not kinematicleg in legsblocked and legraycast.is_colliding():
#		legpivot2.global_position = global_position
		legblockedto = legraycast.get_collision_point()
		legsblocked[kinematicleg] = legraycast.get_collision_point()
		leg1.mesh.size.x = legs_length
		leg2.mesh.size.x = legs_length
	elif kinematicleg in legsblocked and not kinematicleg in legsgoingtoblockedpos:
#		legpivot2.global_position = legsblocked[kinematicleg]
		_leg_going_to_blocked_position(kinematicleg, 20)
	elif kinematicleg in legsblocked and kinematicleg in legsgoingtoblockedpos:
		_leg_going_to_blocked_position(kinematicleg, 10)
	else:
		legpivot2.global_position = lerp(legpivot2.global_position, idle_pos.global_position, 5 * dtime)
		pass
#		legpivot2.global_position = legpivot1.global_position - Vector2(10, 10) * velocity.normalized()
#		legpivot2.global_position = legpivot1.global_position + (legs_length * Vector2(0.25, 0.75) + (-legs_length * Vector2(0.40, -0.60))) * velocity.normalized()
#		legpivot2.global_position = idle_pos.global_position
	
	$MARKER.global_position = legpivot2.global_position
	anglediffgeter.global_position = legpivot2.global_position
	anglediffgeter.look_at(legpivot1.global_position)
	anglediffgeter.rotation_degrees -= 90
	
	var anglediff = anglediffgeter.rotation
	var legdistance = (legpivot1.global_position - legpivot2.global_position).length() 
	var legsize = leg1.mesh.size.x
	
	if first_half:
		legpivot2.rotation = asin((legdistance/2)/legsize) + anglediff
		legpivot1.rotation = -asin((legdistance/2)/legsize) + anglediff
	elif not first_half:
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
