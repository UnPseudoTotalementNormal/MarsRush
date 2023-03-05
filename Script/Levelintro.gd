extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("rickroll"):
		get_tree().reload_current_scene()


func _on_indoor_area_entered(area):
	if not "Player" in area.get_parent().name:
		return
	for i in $Random_walls.get_children():
		if i.is_in_group("indoor"):
			i.visible = false

func _on_indoor_area_exited(area):
	if not "Player" in area.get_parent().name:
		return
	for i in $Random_walls.get_children():
		if i.is_in_group("indoor"):
			i.visible = true


func _on_outdoor_area_entered(area):
	if not "Player" in area.get_parent().name:
		return
	for i in $Random_walls.get_children():
		if i.is_in_group("outdoor"):
			i.visible = false


func _on_outdoor_area_exited(area):
	if not "Player" in area.get_parent().name:
		return
	for i in $Random_walls.get_children():
		if i.is_in_group("outdoor"):
			i.visible = true


func _on_startevent_area_entered(area):
	pass # Replace with function body.


func _on_gotorealgame_area_entered(area):
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Levels/level1.tscn")
