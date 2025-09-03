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
@onready var audio_player = $Sound/SFX/SFX1
@onready var cave = $MapZone/Cave
@onready var end = $MapZone/End

# ---------------------------
# Mob Node References
# ---------------------------
@onready var mob_frog = $Giantfrog
@onready var mob_bamboo = $giantbamboo
@onready var mob_spirit = $giantspirit
@onready var mob_flam = $Giantflam
@onready var boss_snake = $SnakeBoss
@onready var mob_samurai = $giantredsamurai

# ---------------------------
# Wall Mob Node References (Tilemaplayer)
# ---------------------------
@onready var wall_frog = $MobActivatedWall/MobGiantFrog
@onready var wall_bamboo = $MobActivatedWall/MobGiantBamboo
@onready var wall_spirit_and_flam = $MobActivatedWall/MobGiantFlamAndSpirit
@onready var wall_boss_snake = $MobActivatedWall/MobGiantSankeBoss
@onready var wall_samurai = $MobActivatedWall/MobGiantSamurai

# ---------------------------
# Font Settings
# ---------------------------
@export var dialog_font_size: int = 22
@export var name_font_size: int = 26

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
		{"x": 2350, "dialog": "res://pluem/script/เมือง1.json", "triggered": false}
	],
	"City3": [
		{"x": 3450, "dialog": "res://pluem/script/เมือง2.json", "triggered": false}
	],
	"Boss": [
		{"x": 4450, "dialog": "res://pluem/script/ปราสาทไร้มีอณาเขต.json", "triggered": false}
	],
	"End": [
		{"x": 4675, "dialog": "res://pluem/script/ปราสาท2.json", "triggered": false}
	],
}

# ---------------------------
# Story Flow Control
# ---------------------------
var story_step = 0

# ---------------------------
# Ready
# ---------------------------
func _ready():
	dialog.hide()
	$DeadScreen.visible = false
	black_screen.visible = false
	white_button.hide()
	orange_button.hide()
	player.can_move = false

	# ✅ ฟอนต์
	name_label.add_theme_font_size_override("font_size", name_font_size)
	text_label.add_theme_font_size_override("normal_font_size", dialog_font_size)

	# ✅ สัญญาณ HP
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	_update_health_label(player.current_health, player.max_health)

	# ✅ สัญญาณตายของ player
	if player.has_signal("died"):
		print("sad")
		player.died.connect(_on_player_died)

	# ✅ Connect mob signals
	_connect_mob_signals()

	# ✅ Connect buttons
	next_button.pressed.connect(_on_next_pressed)
	orange_button.pressed.connect(_on_orange_button_pressed)
	white_button.pressed.connect(_on_white_button_pressed)

	# ✅ Connect zones
	for zone in map_zone.get_children():
		if zone is Area2D:
			zone.area_entered.connect(_on_zone_entered.bind(zone))

	# เริ่ม story
	story_step = 0
	start_story()
	
	
	
func _on_player_died() -> void:
	$DeadScreen.visible = true 
	player.can_move = false

# ---------------------------
# Connect Mob Signals
# ---------------------------
func _connect_mob_signals():
	if mob_frog and mob_frog.has_signal("died"):
		mob_frog.died.connect(func(): _on_mob_died("frog"), CONNECT_ONE_SHOT)
	if mob_bamboo and mob_bamboo.has_signal("died"):
		mob_bamboo.died.connect(func(): _on_mob_died("bamboo"), CONNECT_ONE_SHOT)
	if mob_spirit and mob_spirit.has_signal("died"):
		mob_spirit.died.connect(func(): _on_mob_died("spirit"), CONNECT_ONE_SHOT)
	if mob_flam and mob_flam.has_signal("died"):
		mob_flam.died.connect(func(): _on_mob_died("flam"), CONNECT_ONE_SHOT)
	if boss_snake and boss_snake.has_signal("died"):
		boss_snake.died.connect(func(): _on_mob_died("boss_snake"), CONNECT_ONE_SHOT)
	if mob_samurai and mob_samurai.has_signal("died"):
		mob_samurai.died.connect(func(): _on_mob_died("samurai"), CONNECT_ONE_SHOT)

# ---------------------------
# Handle Mob Death
# ---------------------------
func _on_mob_died(mob_name: String):
	match mob_name:
		"frog":
			if wall_frog: wall_frog.queue_free()
		"bamboo":
			if wall_bamboo:
				load_dialog("res://pluem/script/ป่า5-2.json")
				wall_bamboo.queue_free()
		"spirit", "flam":
			if wall_spirit_and_flam: wall_spirit_and_flam.queue_free()
		"boss_snake":
			if wall_boss_snake: wall_boss_snake.queue_free()
		"samurai":
			if wall_samurai: wall_samurai.queue_free()

	print("✅ Mob died:", mob_name, " Wall removed!")

# ---------------------------
# Story Sequence
# ---------------------------
func start_story():
	match story_step:
		0:
			load_dialog("res://pluem/script/ในบ้าน.json") 
			$Sound/Song/Song1.playing = true
		1:
			load_dialog("res://pluem/script/ในบ้าน2.json")
			$Sound/Song/Song1.playing = false
		2:
			load_dialog("res://pluem/script/ในบ้าน3.json")
			$Sound/Song/Song2.playing = true
		3:
			player.global_position = cave.global_position
			black_screen.visible = false
			load_dialog("res://pluem/script/ถ้ำ1.json")
		4:
			$Sound/Song/Song2.playing = false
			white_button.show()
			orange_button.show()
			player.can_move = false
		5:
			player.can_move = true
			$Sound/Song/Song3.playing = true
			print("🎉 Player free to explore")
			#player.global_position = end.global_position 

# ---------------------------
# Player Health
# ---------------------------
func _on_player_health_changed(current_health: int, max_health: int) -> void:
	_update_health_label(current_health, max_health)

func _update_health_label(current_health: int, max_health: int) -> void:
	health_label.text = "HP: %d / %d" % [current_health, max_health]
	var ratio = float(current_health) / float(max_health)
	if ratio > 0.6:
		health_label.add_theme_color_override("font_color", Color(0, 1, 0))
	elif ratio > 0.3:
		health_label.add_theme_color_override("font_color", Color(1, 1, 0))
	else:
		health_label.add_theme_color_override("font_color", Color(1, 0, 0))

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

		if line.get("text", "").find("มีเสียงระเบิด") != -1:
			audio_player.play()
		if line.get("text", "").find("ทำได้ดีมาก นายกำจัดผู้นำของเฮอร์คิวลีส และหยุดการนองเลือดครั้งนี้") != -1:
			$NinjaBlue/Camera2D/BlackSceen.visible = true
		
		
		if line.get("text", "").find("นั่นคงจะเป็นกิเลนคู่ ที่ใช้พลังของคัมภีร์เปลี่ยนตัวเองเป็นตัวประหลาดเหมือนที่ทำกันทุกคน") != -1:
			$Sound/Song/Song3.playing = false
			boss_snake.boss_song.play()
		
		if line.get("text", "").find("เสียงเหมือนผนึกถูกปลดออก") != -1:
			$Sound/SFX/SFX3.play()
			
		if line.get("text", "").find("มีเสียงเครื่องบินนินโฉบลงมาและเกิดเสียงระเบิดขนาดใหญ่ดังขึ้น") != -1:
			$Sound/SFX/SFX1.play()
			
			
	else:
		dialog.hide()
		player.can_move = true
		active_dialog = false

		if story_step == 0:
			black_screen.visible = true

		# ✅ ถ้าอยู่ในโซน End ให้โชว์ Winscreen + เล่น Song4
		if current_zone_name == "End":
			$WinScreen.visible = true
			$Sound/Song/Song4.play()
		else:
			story_step += 1
			start_story()


# ---------------------------
# Next Button Pressed
# ---------------------------
func _on_next_pressed() -> void:
	$Sound/SFX/SFX2.play()
	if not active_dialog:
		return
	current_index += 1
	show_line(current_index)
# ---------------------------
# Keyboard Input
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
		if trigger.has("x") and abs(player.global_position.x - trigger["x"]) < 20:
			triggered = true
		elif trigger.has("y") and abs(player.global_position.y - trigger["y"]) < 20:
			triggered = true
		if triggered:
			trigger["triggered"] = true
			load_dialog(trigger["dialog"])
			break

# ---------------------------
# Zone Entered
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
	black_screen.visible = true
	orange_button.hide()

func _on_white_button_pressed():
	load_dialog("res://pluem/script/ถ้ำ2-2.json")
	black_screen.visible = false
	white_button.hide()
	orange_button.hide()
	story_step = 5
	start_story()


func _on_retry_button_pressed() -> void:
	get_tree().change_scene_to_file("res://GameProject/main_game.tscn")

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://GameProject/menu.tscn")
