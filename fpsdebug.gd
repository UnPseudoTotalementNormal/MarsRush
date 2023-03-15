extends CanvasLayer
var timer = 0

func _physics_process(delta):
	timer += 1 * delta
	var format_timer = timer
	var seconds = 0
	var minutes = 0
	while true:
		if format_timer >= 60:
			format_timer -= 60
			minutes += 1
		elif format_timer >= 1:
			format_timer -= 1
			seconds += 1
		else:
			break
	
	
	$timer.text = str(minutes) + ":" + str(seconds)


func _on_spin_box_value_changed(value):
	Engine.physics_ticks_per_second = value
