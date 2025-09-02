extends CharacterBody2D

# ---------------------------
# Stats
# ---------------------------
@export var max_health: int = 50
var current_health: int

@export var damage_to_player: int = 10
@export var invincible_time: float = 0.5

# ---------------------------
# AI Parameters
# ---------------------------
@export var detect_range: float = 100   # ระยะตรวจเจอผู้เล่น
@export var walk_speed: float = 20      # ความเร็วเดินไล่ล่า
@export var dash_speed: float = 150     # ความเร็วพุ่ง
@export var chase_time: float = 0.5       # ไล่ล่านานเท่าไร ก่อนพุ่ง
@export var pause_time: float = 3       # หยุดพักหลังพุ่ง
@export var dash_duration: float = 1   # เวลาที่พุ่งแต่ละครั้ง

# ---------------------------
# Nodes
# ---------------------------
@onready var sprite_mop: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_zone: Area2D = $DamageZone

# ---------------------------
# State
# ---------------------------
var invincible: bool = false

enum State { IDLE, CHASE, DASH, PAUSE, HIT, DEAD }
var state: State = State.IDLE

var player: CharacterBody2D
var chase_timer := 0.0
var dash_direction := Vector2.ZERO
var dash_count: int = 0   # <<< เพิ่มตัวนับพุ่ง

# ---------------------------
# Ready
# ---------------------------
func _ready() -> void:
	add_to_group("enemy")
	current_health = max_health
	sprite_mop.play("idel")
	damage_zone.area_entered.connect(_on_damage_zone_area_entered)

# ---------------------------
# Physics Process
# ---------------------------
func _physics_process(delta: float) -> void:
	# หา player (ครั้งเดียว)
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

	match state:
		State.IDLE:
			_play("idel")
			if player and global_position.distance_to(player.global_position) < detect_range:
				state = State.CHASE
				chase_timer = 0.0

		State.CHASE:
			_play("walk")
			if player:
				var dir = (player.global_position - global_position).normalized()
				velocity = dir * walk_speed
				move_and_slide()
				chase_timer += delta
				if chase_timer >= chase_time:
					state = State.DASH
					dash_direction = dir
			else:
				state = State.IDLE

		State.DASH:
			_play("walk") # หรือ animation dash แยก
			velocity = dash_direction * dash_speed
			move_and_slide()
			await get_tree().create_timer(dash_duration).timeout
			velocity = Vector2.ZERO

			dash_count += 1
			if dash_count < 3:
				# ยังไม่ครบ 3 รอบ → ไล่ล่าต่อแล้วจะพุ่งอีก
				state = State.CHASE
				chase_timer = 0.0
			else:
				# ครบ 3 รอบ → หยุดพัก
				state = State.PAUSE

		State.PAUSE:
			_play("idel")
			velocity = Vector2.ZERO
			await get_tree().create_timer(pause_time).timeout
			state = State.CHASE
			chase_timer = 0.0
			dash_count = 0   # รีเซ็ตจำนวนพุ่ง

		State.HIT:
			_play("hit")

		State.DEAD:
			queue_free()

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
	if invincible:
		return
	
	current_health -= amount

	if current_health <= 0:
		die()
		return
	
	state = State.HIT
	_play("hit")

	invincible = true
	modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(invincible_time).timeout
	invincible = false
	modulate = Color(1, 1, 1)

	state = State.IDLE

func die() -> void:
	state = State.DEAD
	_play("hit")  # หรือ animation "die"
	await sprite_mop.animation_finished

	# จางหายเฉพาะ sprite
	var tween = create_tween()
	tween.tween_property(sprite_mop, "modulate:a", 0.0, 1.0) # จางใน 1 วินาที
	await tween.finished
	

	queue_free()



func _play(name: String) -> void:
	if sprite_mop.animation != name:
		sprite_mop.play(name)
