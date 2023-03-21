extends Node2D
###particles###
var bombpart = preload("res://Particles/bomb_particles.tscn")
var cloudpart = preload("res://Particles/cloudparticles.tscn")
var shotpart = preload("res://Particles/shot_particles.tscn")
var shottrail = preload("res://Particles/shot_trails.tscn")
@onready var all_part = [bombpart, cloudpart, shotpart]
###############

var basicrebel = preload("res://Entities/BasicRebel.tscn")
var spider = preload("res://Entities/EnnemySpider.tscn")
var player_inst = preload("res://Entities/Player.tscn")
var store_ennemi = {}
var playerspawn = Vector2.ZERO
var enneminode = null

var playerinventory = ["hand"]

var chronoawaiting = false
var time: int = 0

var mobile: bool = false

var sun: DirectionalLight2D = null

func _ready():
	if OS.get_name() == "Android" or OS.get_name() == "IOS":
		var leftclickshootevent = InputMap.action_get_events("shoot")
		InputMap.action_erase_event("shoot", leftclickshootevent[0])
		mobile = true
		Engine.physics_ticks_per_second = 30
	
	enneminode = get_tree().current_scene.find_child("EnnemiNode")
	sun = get_tree().current_scene.find_child("Sun")
	
	if enneminode != null:
		for i in enneminode.get_children():
			store_ennemi[i.name] = i.global_position
	
	var Player = get_tree().current_scene.find_child("Player")
	if Player != null:
		playerspawn = Player.global_position
		playerinventory = Player.get("inventory")
	
	for i in all_part:
		var newpart: GPUParticles2D = i.instantiate()
		newpart.global_position = Vector2.ZERO
		newpart.emitting = true
		get_tree().current_scene.add_child(newpart)
		await get_tree().physics_frame
		newpart.queue_free()
	var newtrail: Line2D = shottrail.instantiate()
	newtrail.global_position = Vector2.ZERO
	get_tree().current_scene.add_child(newtrail)
	await get_tree().physics_frame
	newtrail.queue_free()
	

func _process(delta):
	if Input.is_action_just_pressed("fullscreen"):
		pass
	
	if sun != null:
		sun.rotate(0.01*delta)
	
	var fps = find_child("fps")
	if fps:
		fps.text = str(Engine.get_frames_per_second()) + "fps"

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
	for k in store_ennemi:
		var mob = null
		if "BasicRebel" in k:
			mob = basicrebel.instantiate()
		elif "Spider" in k:
			mob = spider.instantiate()
		if not mob:
			continue
		mob.global_position = store_ennemi.get(k)
		enneminode.add_child(mob)
	var splayer = player_inst.instantiate()
	splayer.global_position = playerspawn
	splayer.set("inventory", playerinventory)
	splayer.set("mobile", mobile)
	get_tree().current_scene.add_child(splayer)
