extends Area2D



func _on_area_entered(area):
	if "Player" in area.get_parent().name:
		var player = area.get_parent()
		var playerinventory = player.get("inventory")
		if not playerinventory.has("gun"):
			playerinventory.append("gun")
		get_tree().current_scene.set("playerinventory", playerinventory)
		$CollisionShape2D.queue_free()
		$guunsprite.queue_free()
		$CanvasLayer.visible = true
		await get_tree().create_timer(10).timeout
		queue_free()
