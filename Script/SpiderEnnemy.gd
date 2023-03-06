extends RigidBody2D

@onready var legraycast: RayCast2D = $Legs/leg1/legraycast

@onready var legpivot1 = $Legs/leg1/LegPivot1
@onready var legpivot2 = $Legs/leg1/LegPivot2
@onready var leg1 = $Legs/leg1/LegPivot1/MeshInstance2D
@onready var leg2 = $Legs/leg1/LegPivot2/MeshInstance2D2

@onready var anglediffgeter = $Legs/leg1/anglehaver

var legblocked = false
var legblockedto = Vector2.ZERO

func _physics_process(delta):
	legraycast.target_position.y = -leg1.mesh.size.x * 2
		
	if legraycast.is_colliding() or legblocked:
		if not legblocked:
			legpivot2.global_position = legraycast.get_collision_point()
			legblockedto = legraycast.get_collision_point()
		else:
			legpivot2.global_position = legblockedto
		
		anglediffgeter.global_position = legpivot2.global_position
		anglediffgeter.look_at(legpivot1.global_position)
		anglediffgeter.rotation_degrees -= 90
		var anglediff = anglediffgeter.rotation
		
		var legdistance = (legpivot1.global_position - legpivot2.global_position).length() 
		var legsize = leg1.mesh.size.x
		legpivot2.rotation = asin((legdistance/2)/legsize) + anglediff
		legpivot1.rotation = -asin((legdistance/2)/legsize) + anglediff
		legblocked = true
	
	if legblocked:
		var legdistance = (legpivot1.global_position - legpivot2.global_position).length()
		var legsize = leg1.mesh.size.x
		if legdistance > legsize*2:
			legblocked = false
	
	global_position = get_global_mouse_position()
















func _raycast_leg():
	if legraycast.is_colliding():
		legpivot2.global_position = legraycast.get_collision_point()
		var legdistance = (legpivot1.global_position - legpivot2.global_position).length() / 2
		var legsize = leg1.mesh.size.x
		legpivot2.rotation = asin(legdistance/legsize)
		legpivot1.rotation = -asin(legdistance/legsize)

func _shapecast_leg():
	if $ShapeCast2D.is_colliding():
		legpivot2.global_position = $ShapeCast2D.get_collision_point(0)
		var legdistance = (legpivot1.global_position - legpivot2.global_position).length() / 2
		var legsize = leg1.mesh.size.x
		legpivot2.rotation = asin(legdistance/legsize)
		legpivot1.rotation = -asin(legdistance/legsize)
