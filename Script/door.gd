extends StaticBody2D
@export var space_airlock: bool = false
var player_in_space: bool = false
var player: RigidBody2D = null

var player_in_area = []
var open: bool = false

func _on_indoor_area_entered(area):
	if _check_player(area):
		if space_airlock:
			player_in_space = true
			player.in_space = player_in_space
		player_in_area.append("indoor")
		_open_door(true)
	elif area.get_parent() is RigidBody2D:
		_open_door(false)

func _on_indoor_area_exited(area):
	if _check_player(area):
		if not player_in_area.has("outdoor"):
			player_in_space = false
			player.in_space = player_in_space
			_close_door(true)
		player_in_area.erase("indoor")
	elif area.get_parent() is RigidBody2D:
		_close_door(false)

func _on_outdoor_area_entered(area):
	if _check_player(area):
		player_in_area.append("outdoor")
		_open_door(true)
	elif area.get_parent() is RigidBody2D:
		_open_door(false)

func _on_outdoor_area_exited(area):
	if _check_player(area):
		if not player_in_area.has("indoor"):
			if space_airlock:
				player_in_space = true
				player.in_space = player_in_space
			_close_door(true)
		player_in_area.erase("outdoor")
	elif area.get_parent() is RigidBody2D:
		_close_door(false)

func _open_door(is_player):
	if open:
		return
	$CollisionShape2D.set_deferred("disabled", true)
	visible = false
	open = true
	if is_player:
		SoundSystem.play_sound("res://sound/doors/dooropening.mp3", "door", 0.0)
	else:
		SoundSystem.play_sound("res://sound/doors/dooropening.mp3", "door", 0.0, global_position)

func _close_door(is_player):
	if not open:
		return
	$CollisionShape2D.set_deferred("disabled", false)
	visible = true
	open = false
	if is_player:
		SoundSystem.play_sound("res://sound/doors/doorclosing.mp3", "door", 0.0)
	else:
		SoundSystem.play_sound("res://sound/doors/doorclosing.mp3", "door", 0.0, global_position)

func _check_player(area):
	if "Player" in area.get_parent().name:
		player = area.get_parent()
		return true
	else:
		return false
