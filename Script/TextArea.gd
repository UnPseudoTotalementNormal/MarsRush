extends Area2D
@export var french_text: String = ""
@export var english_text: String = ""
var already_shown = false

func _on_area_entered(area):
	if "Player" in area.get_parent().name and not already_shown:
		if french_text == "" and english_text != "":
			area.get_parent()._draw_text(english_text)
		elif english_text == "" and french_text != "":
			area.get_parent()._draw_text(french_text)
		else:
			area.get_parent()._draw_text(french_text)
		already_shown = true



func _on_area_exited(area):
	if "Player" in area.get_parent().name:
		area.get_parent()._erase_text()
