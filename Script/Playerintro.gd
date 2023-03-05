extends CharacterBody2D
var dtime: float = 0
var space = false
var moveable = true

var SPEED = 150
var JUMP_VELOCITY = -225

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 980

var in_space_div = 3
var normal_div = 1
var grav_div = 3

var storepnj = null

var discussion = {
	"housepnj1": "Ah tu es enfin réveillé, tout le monde t'attend au bar!",
	"barpnj1": "J'ai vu quelque chose au dessus de nous hier, j'espère que je rêvais",
	"barpnj2": "Tu a déjà ta tenue! ça veut dire que tu part ce soir pour l'ancienne Terre ?",
	"barpnj3": "Fais attention, d'après les nouvelles, l'ancienne Terre s'est encore fait reprendre par les rebelles",
	"barpnj4": "Tu reste pas au bar ? Je comprends tu dois être pressé d'y aller",
	"spacepnj1": "J'ai entendu des bruits d'explosions plus loin... Je vais chercher des armes et prévenir les autres, toi va voir ce qu'il se passe",
	"spacepnj3": "Les rebelles... Ils sont là...",
	"spacepnj2": "amogus",
	"spacerebel1": "Abattez le !",
	"startevent": "En voila un autre! Abattez le !",
	
}


func _physics_process(delta):
	dtime = delta
	if moveable == false:
		$Camera2D.zoom = lerp($Camera2D.zoom, Vector2(0.5, 0.5), 1 * dtime)
		velocity.y = -350
		velocity.x = -150
		rotate(deg_to_rad(600)*dtime)
		move_and_slide()
		return
	if space:
		grav_div = in_space_div
	else:
		grav_div = normal_div
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity/grav_div * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	_outfit()
	_discuss()

	move_and_slide()

func _discuss():
	if Input.is_action_just_pressed("interagir") and storepnj != null:
		var pnjname = storepnj.name
		if pnjname in discussion:
			$CanvasLayer/Talklabel.visible = true
			$CanvasLayer/Talklabel.visible_characters = 0
			$CanvasLayer/Talklabel.text = discussion[pnjname]
			$CanvasLayer/Interagir.visible = false
	$CanvasLayer/Talklabel.visible_characters += 1
		

func _outfit():
	if space:
		$Mesh2.visible = false
		$Mesh.visible = true
	else:
		$Mesh2.visible = true
		$Mesh.visible = false


func _on_areadetector_area_entered(area):
	if "outdoor" in area.name:
		space = true
	elif "indoor" in area.name:
		space = false
	elif "pnj" in area.name:
		$CanvasLayer/Interagir.visible = true
		storepnj = area.get_parent()
	elif "startevent" in area.name:
		$CanvasLayer/Talklabel.visible = true
		$CanvasLayer/Talklabel.visible_characters = 0
		$CanvasLayer/Talklabel.text = discussion.startevent
		$CanvasLayer/Interagir.visible = false
		await get_tree().create_timer(1).timeout
		$AudioStreamPlayer2D.stream = load("res://sound/deltarune explosion greenscreen.mp3")
		$AudioStreamPlayer2D.play()
		moveable = false
		
		

func _on_areadetector_area_exited(area):
	if "pnj" in area.name or "startevent" in area.name:
		$CanvasLayer/Interagir.visible = false
		$CanvasLayer/Talklabel.visible = false
		storepnj = null
