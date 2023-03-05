extends Node2D
###particles###
var bombpart = preload("res://Particles/bomb_particles.tscn")
var cloudpart = preload("res://Particles/cloudparticles.tscn")
var shotpart = preload("res://Particles/shot_particles.tscn")
var shottrail = preload("res://Particles/shot_trails.tscn")
@onready var all_part = [bombpart, cloudpart, shotpart]
###############

var ennemi = preload("res://Entities/ennemi.tscn")
var player_inst = preload("res://Entities/Player.tscn")
var store_ennemi_pos = []
var playerspawn = Vector2.ZERO
var enneminode = null

var playerinventory = ["hand"]

var chronoawaiting = false
var time: int = 0

var mobile: bool = false

func _ready():
	if OS.get_name() == "Android" or OS.get_name() == "IOS":
		var leftclickshootevent = InputMap.action_get_events("shoot")
		InputMap.action_erase_event("shoot", leftclickshootevent[0])
		mobile = true
		Engine.physics_ticks_per_second = 30
	
	enneminode = get_tree().current_scene.find_child("EnnemiNode")
	if enneminode != null:
		for i in enneminode.get_children():
			store_ennemi_pos.append(i.global_position)
	var Player = get_tree().current_scene.find_child("Player")
	if Player != null:
		playerspawn = Player.global_position
		playerinventory = Player.get("inventory")
	
	for i in all_part:
		var newpart: GPUParticles2D = i.instantiate()
		newpart.global_position = Vector2(10000, 10000)
		newpart.emitting = true
		get_tree().current_scene.add_child(newpart)
	var newtrail: Line2D = shottrail.instantiate()
	newtrail.global_position = Vector2(10000, 10000)
	get_tree().current_scene.add_child(newtrail)
	

func _process(delta):
	if Input.is_action_just_pressed("fullscreen"):
		pass

func _physics_process(delta):
	if not chronoawaiting:
		chronoawaiting = true
		await get_tree().create_timer(1, false).timeout
		chronoawaiting = false
		time += 1
		var minute = 0
		var secs = 0
		minute = floori(time/60)
		secs = time - minute * 60
		$CanvasLayer/chrono.text = str(minute) + ":" + str(secs)

func _respawn(wait_time):
	await get_tree().create_timer(wait_time).timeout
	for i in enneminode.get_children():
		i.queue_free()
	for k in store_ennemi_pos:
		var en = ennemi.instantiate()
		en.global_position = k
		enneminode.add_child(en)
	var splayer = player_inst.instantiate()
	splayer.global_position = playerspawn
	splayer.set("inventory", playerinventory)
	splayer.set("mobile", mobile)
	get_tree().current_scene.add_child(splayer)
