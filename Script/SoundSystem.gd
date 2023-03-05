extends Node2D
var all_audio = {}
var space_audio = true

var player: RigidBody2D = null

func _process(delta):
	if player == null:
		player = get_tree().current_scene.find_child("Player")
	_space_audio()

func play_sound(sound: String, category: String = "effect", random_range: float = 0.0, soundposition: Vector2 = Vector2.ZERO):
	var audioplayer = AudioStreamPlayer.new()
	var soundID: String = sound + "_" + str(randf())
	if soundposition != Vector2.ZERO:
		audioplayer = AudioStreamPlayer2D.new()
		audioplayer.global_position = soundposition
		audioplayer.max_distance = 500
	audioplayer.name = soundID
	audioplayer.stream = load(sound)
	randomize()
	audioplayer.pitch_scale = randf_range(1-random_range, 1+random_range)
	audioplayer.autoplay = true
	get_tree().current_scene.add_child.call_deferred(audioplayer)
	all_audio[soundID] = {"category": category, "soundposition": soundposition, "audioplayer": audioplayer}
	await audioplayer.finished
	audioplayer.queue_free()
	all_audio.erase(soundID)


func stop_sound(category: String = "", soundname: String = ""):
	if category == "":
		for i in all_audio:
			if soundname in i:
				var audioplayer = all_audio[i].audioplayer
				all_audio.erase(i)
				audioplayer.queue_free()
	elif category != "":
		for i in all_audio:
			if all_audio[i].category == category:
				var audioplayer = all_audio[i].audioplayer
				all_audio.erase(i)
				audioplayer.queue_free()
	

func _space_audio():
	if space_audio:
		AudioServer.set_bus_effect_enabled(0, 0, true)
		AudioServer.set_bus_effect_enabled(0, 1, true)
	else:
		AudioServer.set_bus_effect_enabled(0, 0, false)
		AudioServer.set_bus_effect_enabled(0, 1, false)
