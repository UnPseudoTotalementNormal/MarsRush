extends CharacterBody2D
@onready var collision = $CollisionShape2D

var health_points: float = 5

func _ready():
	collision.shape.size = Vector2(get_parent().mesh.size.x, get_parent().mesh.size.y)

func _process(delta):
	if health_points <= 0:
		var spider = $"../../..".get_parent().get_parent().get_parent()
		if spider.get("health_points") != null:
			spider.set("health_points", spider.get("health_points") - spider.get("max_health") * 0.2)
		$"../../..".get_parent().queue_free() #delete the leg
		
