extends CanvasLayer
var timer = 0

func _on_165_pressed():
	Engine.physics_ticks_per_second = 165


func _on_30_pressed():
	Engine.physics_ticks_per_second = 30


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
