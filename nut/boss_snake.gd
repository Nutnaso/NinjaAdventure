extends Node2D
class_name Boss

# ---------------------------
# Stats
# ---------------------------
@export var max_health: int = 200
var current_health: int

@export var damage_to_player: int = 20
@export var invincible_time: float = 1

# ---------------------------
# AI Parameters
# ---------------------------
@export var detect_range: float = 50       # ระยะตรวจจับครั้งแรก
@export var move_speed: float = 125         # ความเร็วพื้นฐาน
@export var max_speed: float = 400          # ความเร็วสูงสุดเมื่อผู้เล่นไกล
@export var zigzag_amplitude: float = 300  # ความกว้าง zigzag
@export var zigzag_frequency: float = 10   # ความเร็ว zigzag

# ---------------------------
# Nodes
# ---------------------------
@onready var head = $Head
@onready var body_container = $BodyContainer
@onready var damage_zone: Area2D = $Head/DamageZone

# ---------------------------
# Body setup
# ---------------------------
var body_segments = []
var segment_count = 20
var segment_spacing = 25
var position_history = []

var tex_body1 = preload("res://nut/Body1.png")
var tex_body2 = preload("res://nut/Body2.png")
var tex_body_end = preload("res://nut/BodyEnd.png")

# ---------------------------
# State
# ---------------------------
enum State { IDLE, CHASE, HIT, DEAD }
var state: State = State.IDLE
var invincible: bool = false
var player: CharacterBody2D
var zigzag_timer: float = 0.0
var has_detected_player: bool = false

# ---------------------------
# Ready
# ---------------------------
func _ready():
	add_to_group("enemy")
	current_health = max_health
	spawn_body()
	position_history.append(head.position)
	damage_zone.area_entered.connect(_on_damage_zone_area_entered)

# ---------------------------
# Body Spawn
# ---------------------------
func spawn_body():
	for i in range(segment_count):
		var segment = Sprite2D.new()
		if i == segment_count - 1:
			segment.texture = tex_body_end
		else:
			segment.texture = tex_body1 if i % 2 == 0 else tex_body2
		body_container.add_child(segment)
		body_segments.append(segment)

# ---------------------------
# Physics Process
# ---------------------------
# ---------------------------
# Physics Process
# ---------------------------
func _physics_process(delta):
	match state:
		State.IDLE:
			if _can_see_player():
				has_detected_player = true
				state = State.CHASE

		State.CHASE:
			if not player:
				_find_player()
			if player:
				_move_head(delta)

		State.HIT:
			# หยุดนิ่ง 0.5 วินาที
			pass  # ไม่ขยับหัว

		State.DEAD:
			pass

	_update_body()


# ---------------------------
# Move Head (zigzag follow with dynamic speed)
# ---------------------------
func _move_head(delta):
	if not player:
		return

	var distance_to_player = head.global_position.distance_to(player.global_position)

	# ความเร็วปรับตามระยะ
	var speed_factor = 1.0
	if distance_to_player > detect_range:
		speed_factor = 1.0 + (distance_to_player - detect_range) / 300.0 # ปรับ scale factor ตามต้องการ
	var current_speed = min(move_speed * speed_factor, max_speed) # จำกัด max_speed

	# ทิศทางไปยังผู้เล่น
	var to_player = (player.global_position - head.global_position).normalized()
	zigzag_timer += delta * zigzag_frequency

	# zigzag
	var perp = Vector2(-to_player.y, to_player.x) * sin(zigzag_timer) * (zigzag_amplitude / 100.0)
	var move_dir = (to_player + perp).normalized()

	# เคลื่อนที่
	head.position += move_dir * current_speed * delta

	# เก็บตำแหน่งหัว
	position_history.insert(0, head.position)
	if position_history.size() > segment_count * segment_spacing + 1:
		position_history.resize(segment_count * segment_spacing + 1)

# ---------------------------
# Update Body
# ---------------------------
func _update_body():
	for i in range(body_segments.size()):
		var index = (i + 1) * segment_spacing
		if index < position_history.size():
			body_segments[i].position = position_history[index]
			if i < body_segments.size() - 1:
				var prev_index = index - 1
				if prev_index >= 0 and prev_index < position_history.size():
					var dir = position_history[prev_index] - position_history[index]
					body_segments[i].rotation = dir.angle()
			else:
				var prev_pos = body_segments[i - 1].position
				var dir = prev_pos - body_segments[i].position
				body_segments[i].rotation = dir.angle()

# ---------------------------
# Detection
# ---------------------------
func _can_see_player() -> bool:
	if not player:
		_find_player()
	if player:
		if not has_detected_player:
			return head.global_position.distance_to(player.global_position) <= detect_range
		else:
			return true
	return false

func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

# ---------------------------
# Damage Handling
# ---------------------------
func _on_damage_zone_area_entered(area: Area2D) -> void:
	if area.name == "AttackZone":
		return
	var player_node = area.get_parent()
	while player_node and not player_node.is_in_group("player"):
		player_node = player_node.get_parent()
	if player_node:
		player_node.take_damage(damage_to_player)

func take_damage(amount: int) -> void:
	if invincible or state == State.DEAD:
		return

	current_health -= amount
	if current_health <= 0:
		die()
		return

	# Boss โดนตี -> หยุด 0.5 วิ
	state = State.HIT
	invincible = true
	modulate = Color(1, 0.5, 0.5)

	# รอ 0.5 วินาที
	await get_tree().create_timer(0.5).timeout

	invincible = false
	modulate = Color(1, 1, 1)
	state = State.CHASE
	has_detected_player = true

func die() -> void:
	state = State.DEAD
	queue_free()
