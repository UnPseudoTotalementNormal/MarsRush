extends RigidBody2D
var bomb = preload("res://Entities/ennemi_bomb.tscn")
var bomb_part = preload("res://Particles/bomb_particles.tscn")
var dpart = preload("res://Entities/death_part.tscn")
var Player: RigidBody2D = null
var Nav_region: NavigationRegion2D = null
var script_ready = false

var path: NodePath

var health_points = 100

@export var move_force: float = 9000
@export var shoot_force: float = 120

var player_seen = false

var movetime = 2.5
var shootbombtime = 4.5

func _ready():
	await get_tree().create_timer(0.05).timeout
	_find_player()
	_find_nav()
	script_ready = true

func _find_player():
	Player = get_tree().current_scene.find_child("Player", true, false)

func _find_nav():
	Nav_region = get_tree().current_scene.find_child("NavigationRegion2D")

func _physics_process(delta):
	if not script_ready:
		return
	
	if health_points <= 0:
		var deathpart = dpart.instantiate()
		deathpart.global_position = global_position
		get_tree().current_scene.add_child(deathpart)
		queue_free()
	
	if Player == null or Nav_region == null:
		_find_player()
		return
	
	if not player_seen:
		if (Player.global_position - global_position).length() > $RayCast2D.target_position.x:
			return
		_search_player()
		return
	
	$NavigationAgent2D.set_target_position(Player.global_position)


func _search_player():
	$RayCast2D.look_at(Player.global_position)
	if $RayCast2D.get_collider() == Player:
		player_seen = true
		$Movetimer.start(movetime)
		$Shootbombtimer.start(shootbombtime)


func _on_movetimer_timeout():
	if $NavigationAgent2D.get_next_path_position() != Vector2.ZERO:
		var dist: Vector2 = global_position - $NavigationAgent2D.get_next_path_position()
		var dist_norm: Vector2 = dist.normalized()
		linear_velocity = Vector2.ZERO
		apply_central_impulse(-dist_norm * move_force)


func _on_shootbombtimer_timeout():
	if Player == null:
		return
	var s_bomb: RigidBody2D = bomb.instantiate()
	var s_part = bomb_part.instantiate()
	s_part.set("bomb", s_bomb)
	s_bomb.global_position = global_position
	s_bomb.set("from", self)
	get_tree().current_scene.add_child(s_bomb)
	get_tree().current_scene.add_child(s_part)
	await get_tree().physics_frame
	var dist: Vector2 = global_position - Player.global_position
	var dist_norm: Vector2 = dist.normalized()
	s_bomb.apply_central_impulse(-dist_norm * shoot_force)
