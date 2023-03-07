extends CharacterBody2D
@export var legs_length: float = 20
@export var legs_width: float = 2

@onready var Body: MeshInstance2D = $Body

@onready var Legs: Node2D = $Legs

@onready var legraycast: RayCast2D = $Legs/leg1/legraycast

var legsblocked = {}
var legblockedto = Vector2.ZERO


func _physics_process(delta):
	var half_legs = Legs.get_child_count() / 2
	var leg_count = 1
	for i in Legs.get_children():
		if leg_count <= half_legs:
			_kinematic_leg(i, false)
		else:
			_kinematic_leg(i, true)
		leg_count += 1
	
	Legs.look_at(global_position + Vector2(10, 10) * velocity.normalized())
	Body.look_at(global_position + Vector2(10, 10) * velocity.normalized())
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
	legraycast.force_raycast_update()
	
	if legraycast.is_colliding() or kinematicleg in legsblocked:
		if not kinematicleg in legsblocked:
			legpivot2.global_position = legraycast.get_collision_point()
			legblockedto = legraycast.get_collision_point()
			legsblocked[kinematicleg] = legpivot2.global_position
		else:
			legpivot2.global_position = legsblocked[kinematicleg]
		
		anglediffgeter.global_position = legpivot2.global_position
		anglediffgeter.look_at(legpivot1.global_position)
		anglediffgeter.rotation_degrees -= 90
		
		var anglediff = anglediffgeter.rotation
		var legdistance = (legpivot1.global_position - legpivot2.global_position).length() 
		var legsize = leg1.mesh.size.x
		
		if first_half:
			legpivot2.rotation = asin((legdistance/2)/legsize) + anglediff
			legpivot1.rotation = -asin((legdistance/2)/legsize) + anglediff
		else:
			legpivot2.rotation = -asin((legdistance/2)/legsize) + anglediff + deg_to_rad(180)
			legpivot1.rotation = asin((legdistance/2)/legsize) + anglediff + deg_to_rad(180)
	
	if kinematicleg in legsblocked:
		var legdistance = (legpivot1.global_position - legpivot2.global_position).length()
		var legsize = leg1.mesh.size.x
		if legdistance > legsize*2:
			legsblocked.erase(kinematicleg)


func _set_mesh_length_and_width(mesh: Array):
	for i in mesh:
		i.mesh.size.x = legs_length
		i.mesh.size.y = legs_width
