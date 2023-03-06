extends RigidBody2D

@onready var Legs: Node2D = $Legs

@onready var legraycast: RayCast2D = $Legs/leg1/legraycast

var legsblocked = {}
var legblockedto = Vector2.ZERO

func _physics_process(delta):
	for i in Legs.get_children():
		_kinematic_leg(i)
	
	global_position = get_global_mouse_position()



func _kinematic_leg(kinematicleg):
	var legpivot1: Node2D = kinematicleg.find_child("LegPivot1")
	var legpivot2: Node2D = kinematicleg.find_child("LegPivot2")
	var leg1: MeshInstance2D = legpivot1.find_child("MeshInstance2D")
	var leg2: MeshInstance2D = legpivot2.find_child("MeshInstance2D2")
	var legraycast: RayCast2D = kinematicleg.find_child("legraycast")
	var anglediffgeter: Node2D = kinematicleg.find_child("anglehaver")
	
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
		
		legpivot2.rotation = asin((legdistance/2)/legsize) + anglediff
		legpivot1.rotation = -asin((legdistance/2)/legsize) + anglediff
	
	if kinematicleg in legsblocked:
		var legdistance = (legpivot1.global_position - legpivot2.global_position).length()
		var legsize = leg1.mesh.size.x
		if legdistance > legsize*2:
			legsblocked.erase(kinematicleg)
