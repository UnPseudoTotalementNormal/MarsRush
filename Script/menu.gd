extends Node2D



func _on_play_pressed():
	get_tree().change_scene_to_file("res://Levels/intro.tscn")


func _on_skipintro_pressed():
	get_tree().change_scene_to_file("res://Levels/level1.tscn")

func _on_quit_pressed():
	get_tree().quit()
