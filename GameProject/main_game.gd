extends Node2D

# ---------------------------
# Node References
# ---------------------------
@onready var dialog = $NinjaBlue/Camera2D/dialog
@onready var name_label = $NinjaBlue/Camera2D/dialog/Panel/Label
@onready var text_label = $NinjaBlue/Camera2D/dialog/Panel/RichTextLabel
@onready var next_button = $NinjaBlue/Camera2D/dialog/Panel/Button
@onready var player  = $NinjaBlue
@onready var camera  = $NinjaBlue/Camera2D
@onready var map_zone = $MapZone   # รวม Desert, Forest1

# ---------------------------
# Dialog Data
# ---------------------------
var dialog_data = []
var current_index = 0

# ---------------------------
# Ready
# ---------------------------
func _ready():
	load_dialog("res://dialog.json")
	show_line(0)
	next_button.pressed.connect(_on_next_pressed)

	player.add_to_group("player")

	# เชื่อมสัญญาณทุก Zone
	for zone in map_zone.get_children():
		if zone is Area2D:
			zone.connect("area_entered", Callable(self, "_on_zone_entered").bind(zone))

# ---------------------------
# Load Dialog
# ---------------------------
func load_dialog(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.parse_string(content)
		if typeof(json) == TYPE_DICTIONARY:
			dialog_data = json.get("dialogs", [])
		else:
			push_error("Failed to parse dialog JSON.")
	else:
		push_error("Cannot open dialog file: %s" % file_path)

# ---------------------------
# Show Line
# ---------------------------
func show_line(index: int):
	if index < dialog_data.size():
		var line = dialog_data[index]
		name_label.text = line.get("name", "")
		text_label.text = line.get("text", "")
		dialog.show()
		player.can_move = false
	else:
		dialog.hide()
		player.can_move = true
		current_index = dialog_data.size()

# ---------------------------
# Next Button Pressed
# ---------------------------
func _on_next_pressed():
	current_index += 1
	show_line(current_index)

# ---------------------------
# Keyboard Input (Enter/Space)
# ---------------------------
func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		_on_next_pressed()

# ---------------------------
# Camera Limit Logic
# ---------------------------
func _on_zone_entered(area: Area2D, zone: Area2D):
	if area.name == "DamageZone":  # ตรวจเฉพาะ DamageZone ของ Player
		# ตรวจชื่อ Zone
		match zone.name:
			"Desert":
				print("Player entered Desert zone")
			"Forest1":
				print("Player entered Forest1 zone")
			_:
				print("Player entered zone: ", zone.name)

		# ตั้งค่า limit กล้อง
		var shape = zone.get_node("CollisionShape2D").shape
		if shape is RectangleShape2D:
			var rect_size = shape.size
			var rect_pos = zone.global_position - rect_size / 2

			camera.limit_left   = int(rect_pos.x)
			camera.limit_top    = int(rect_pos.y)
			camera.limit_right  = int(rect_pos.x + rect_size.x)
			camera.limit_bottom = int(rect_pos.y + rect_size.y)

			# Debug ตำแหน่ง limit ของกล้อง
			print("Camera limits set:",
				" left=", camera.limit_left,
				" top=", camera.limit_top,
				" right=", camera.limit_right,
				" bottom=", camera.limit_bottom)
