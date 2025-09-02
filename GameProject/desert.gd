extends Area2D

func _ready():
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(area: Area2D) -> void:
	if area.name == "DamageZone":  # ถ้าเป็น DamageZone ของ Player
		var player = area.get_parent()  # DamageZone เป็นลูกของ Player
		var camera = player.get_node("Camera2D")
		var shape = $CollisionShape2D.shape
		if shape is RectangleShape2D:
			var rect_size = shape.size
			var rect_pos = global_position - rect_size / 2

			camera.limit_left   = int(rect_pos.x)
			camera.limit_top    = int(rect_pos.y)
			camera.limit_right  = int(rect_pos.x + rect_size.x)
			camera.limit_bottom = int(rect_pos.y + rect_size.y)
