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
@onready var map_zone = $MapZone
@onready var health_label = $NinjaBlue/Camera2D/Status/HealthBar 
@onready var black_screen = $NinjaBlue/Camera2D/BlackSceen
@onready var white_button = $ChooseEnd/WhiteButton
@onready var orange_button = $ChooseEnd/OrangeButton
@onready var audio_player = $Sound/SFX/AudioStreamPlayer  # ต้องมี AudioStreamPlayer ใน scene
@onready var cave = $MapZone/Cave        # จุดวาร์ปถ้ำ

# ---------------------------
# Dialog Data
# ---------------------------
var dialog_data = []
var current_index = 0
var active_dialog = false

# ---------------------------
# Current Zone ของ Player
# ---------------------------
var current_zone_name = ""

# ---------------------------
# Event Trigger Data
# ---------------------------
var event_triggers = {
	"Home": [
		{"x": 0, "dialog": "res://pluem/script/ชนบท.json", "triggered": false}
	],
	"Desert": [
		{"x": 350, "dialog": "res://pluem/script/ชนบทBoss.json", "triggered": false}
	],
	"Forest1": [
		{"x": 650, "dialog": "res://pluem/script/ป่า1.json", "triggered": false}
	],
	"Forest3": [
		{"y": 450, "dialog": "res://pluem/script/ป่า4-1-1.json", "triggered": false},
		{"x": 1300, "dialog": "res://pluem/script/ป่า4-1-2.json", "triggered": false}
	],
	"Forest4": [
		{"x": 1000, "dialog": "res://pluem/script/ป่า4-1-3.json", "triggered": false}
	],
	"Forest5": [
		{"x": 1750, "dialog": "res://pluem/script/ป่า4-2.json", "triggered": false},
		{"x": 2050, "dialog": "res://pluem/script/ป่า5-1.json", "triggered": false}
	],
	"City1": [
		{"x": 2625, "dialog": "res://pluem/script/ป่า5-2.json", "triggered": false}
	],	
	"City2": [
		{"x": 2850, "dialog": "res://pluem/script/เมือง1.json", "triggered": false}
	],
	"City3": [
		{"x": 3450, "dialog": "res://pluem/script/เมือง2.json", "triggered": false}
	],
	"Boss": [
		{"x": 4450, "dialog": "res://pluem/script/ปราสาทไร้มีอณาเขต.json", "triggered": false}
	],
}

# ---------------------------
# Story Flow Control
# ---------------------------
var story_step = 0   # คุมลำดับเหตุการณ์เริ่มเกม

# ---------------------------
# Ready
# ---------------------------
func _ready():
	dialog.hide()
	black_screen.visible = false
	white_button.hide()
	orange_button.hide()
	player.can_move = false
	
	# เซ็ตค่าเลือดเริ่มต้น
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	_update_health_label(player.current_health, player.max_health)

	# connect signal จากทุก Zone
	for zone in map_zone.get_children():
		if zone is Area2D:
			zone.area_entered.connect(_on_zone_entered.bind(zone))

	# เซ็ตกล้องเริ่มเกม
	camera.global_position = Vector2(-125, 100)

	# เริ่ม story flow
	story_step = 0
	start_story()

# ---------------------------
# Story Sequence
# ---------------------------
func start_story():
	match story_step:
		0:
			load_dialog("res://pluem/script/ในบ้าน.json")
		1:
			load_dialog("res://pluem/script/ในบ้าน2.json")
		2:
			load_dialog("res://pluem/script/ในบ้าน3.json")
		3:
			player.global_position = cave.global_position
			$NinjaBlue/Camera2D/BlackSceen.visible = false
			load_dialog("res://pluem/script/ถ้ำ1.json")
		4:
			white_button.show()
			orange_button.show()
			player.can_move = false
		5:
			player.can_move = true
			print("🎉 Player free to explore")

# ---------------------------
# Player Health
# ---------------------------
func _on_player_health_changed(current_health: int, max_health: int) -> void:
	_update_health_label(current_health, max_health)

func _update_health_label(current_health: int, max_health: int) -> void:
	health_label.text = "HP: %d / %d" % [current_health, max_health]

	var ratio = float(current_health) / float(max_health)
	if ratio > 0.6:
		health_label.add_theme_color_override("font_color", Color(0, 1, 0)) # เขียว
	elif ratio > 0.3:
		health_label.add_theme_color_override("font_color", Color(1, 1, 0)) # เหลือง
	else:
		health_label.add_theme_color_override("font_color", Color(1, 0, 0)) # แดง

# ---------------------------
# Process
# ---------------------------
func _process(_delta):
	if current_zone_name != "":
		check_triggers(current_zone_name)

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
			current_index = 0
			show_line(0)
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
		active_dialog = true

		# ✅ เล่นเสียงตอนเจอข้อความพิเศษ
		if line.get("text", "").find("มีเสียงระเบิด") != -1:
			audio_player.play()
	else:
		dialog.hide()
		player.can_move = true
		active_dialog = false

		# ✅ event พิเศษหลังจบบทสนทนา
		if story_step == 0:
			black_screen.visible = true
		story_step += 1
		start_story()

# ---------------------------
# Next Button Pressed
# ---------------------------
func _on_next_pressed():
	if not active_dialog:
		return
	current_index += 1
	show_line(current_index)

# ---------------------------
# Keyboard Input (Enter/Space)
# ---------------------------
func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and active_dialog:
		_on_next_pressed()

# ---------------------------
# Check Triggers
# ---------------------------
func check_triggers(zone_name: String):
	if not event_triggers.has(zone_name):
		return

	for trigger in event_triggers[zone_name]:
		if trigger.get("triggered", false):
			continue

		var triggered = false

		if trigger.has("pos"):
			if player.global_position.distance_to(trigger["pos"]) < 30:
				triggered = true
		elif trigger.has("x"):
			if abs(player.global_position.x - trigger["x"]) < 20:
				triggered = true
		elif trigger.has("y"):
			if abs(player.global_position.y - trigger["y"]) < 20:
				triggered = true

		if triggered:
			trigger["triggered"] = true
			load_dialog(trigger["dialog"])
			break

# ---------------------------
# Zone Entered (Camera + Zone Update)
# ---------------------------
func _on_zone_entered(area: Area2D, zone: Area2D):
	if area.name == "DamageZone":
		current_zone_name = zone.name
		print("Player entered zone: ", current_zone_name)

		var shape = zone.get_node("CollisionShape2D").shape
		if shape is RectangleShape2D:
			var rect_size = shape.size
			var rect_pos = zone.global_position - rect_size / 2

			camera.limit_left   = int(rect_pos.x)
			camera.limit_top    = int(rect_pos.y)
			camera.limit_right  = int(rect_pos.x + rect_size.x)
			camera.limit_bottom = int(rect_pos.y + rect_size.y)

# ---------------------------
# Choice Buttons
# ---------------------------
func _on_orange_button_pressed() -> void:
	load_dialog("res://pluem/script/ถ้ำ2-1.json")
	orange_button.hide()



func _on_white_button_pressed():
	load_dialog("res://pluem/script/ถ้ำ2-2.json")
	white_button.hide()
	orange_button.hide()
	story_step = 5
	start_story()
