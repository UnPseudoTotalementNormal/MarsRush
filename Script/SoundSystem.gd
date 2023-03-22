extends Node2D
var all_audio = {}
var space_audio = true

var player: RigidBody2D = null

func _process(delta):
	if not player:
		player = get_tree().current_scene.find_child("Player", true, false)
		return
	_space_audio()
	_audio_context()

func play_sound(sound: String, category: String = "effect", random_range: float = 0.0, soundposition: Vector2 = Vector2.ZERO, db_added: float = 0.0):
	var audioplayer = AudioStreamPlayer.new()
	var soundID: String = sound + "_" + str(randf())
	if soundposition != Vector2.ZERO:
		audioplayer = AudioStreamPlayer2D.new()
		audioplayer.global_position = soundposition
#		audioplayer.distan
		audioplayer.max_distance = 500
	audioplayer.name = soundID
	audioplayer.stream = load(sound)
	randomize()
	audioplayer.pitch_scale = randf_range(1-random_range, 1+random_range)
	audioplayer.autoplay = true
	audioplayer.volume_db += db_added
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
				if audioplayer:
					audioplayer.queue_free()
	elif category != "":
		for i in all_audio:
			if all_audio[i].category == category:
				var audioplayer = all_audio[i].audioplayer
				all_audio.erase(i)
				if audioplayer:
					audioplayer.queue_free()

func is_playing(soundname: String):
	for i in all_audio:
		if soundname in i:
			return true
	return false

func _audio_context():
	for audio in all_audio:
		if all_audio[audio].soundposition == Vector2.ZERO:
			continue
		var distance = all_audio[audio].soundposition - player.global_position
		var distance_len = distance.length()
		var close = 100
		var medium = 200
		var far = 300
		var audioplayer: AudioStreamPlayer2D
		audioplayer = all_audio[audio].audioplayer
		if space_audio:
			audioplayer.bus = "master"
			continue
		if distance_len > far:
			audioplayer.bus = "far"
		elif distance_len > medium:
			audioplayer.bus = "far"
		else:
			audioplayer.bus = "close"

func _space_audio():
	if space_audio:
		AudioServer.set_bus_effect_enabled(0, 0, true)
		AudioServer.set_bus_effect_enabled(0, 1, true)
		AudioServer.set_bus_effect_enabled(0, 2, false)
	else:
		AudioServer.set_bus_effect_enabled(0, 0, false)
		AudioServer.set_bus_effect_enabled(0, 1, false)
		AudioServer.set_bus_effect_enabled(0, 2, true)
