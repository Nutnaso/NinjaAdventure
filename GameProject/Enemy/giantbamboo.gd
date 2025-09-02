extends CharacterBody2D

# -------------------------------
# Stats
# -------------------------------
@export var max_health: int = 50
var current_health: int

@export var damage_to_player: int = 10
@export var invincible_time: float = 0.5

# -------------------------------
# Behavior Parameters
# -------------------------------
@export var detect_range: float = 70        # ระยะตรวจจับผู้เล่น (ใช้แค่ครั้งแรก)
@export var float_height: float = 80        # ความสูงที่ลอยเหนือผู้เล่น
@export var dash_speed: float = 150         # ความเร็วพุ่ง
@export var float_time: float = 2           # เวลาที่ลอยเหนือผู้เล่น
@export var shake_time: float = 0.5         # เวลาที่สั่น
@export var shake_strength: float = 3.0     # ความแรงของการสั่น (ยิ่งเยอะยิ่งสั่นแรง)
@export var rest_time: float = 1.5          # เวลาพักหลังพุ่งพลาด

# -------------------------------
# Nodes
# -------------------------------
@onready var sprite_mop: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_zone: Area2D = $DamageZone

# -------------------------------
# State
# -------------------------------
var invincible: bool = false
var player_ref: Node2D = null
var dash_target: Vector2 = Vector2.ZERO

enum State { IDLE, FLOAT, SHAKE, DASH, REST, HIT, DEAD }
var state: State = State.IDLE

# -------------------------------
# Ready
# -------------------------------
func _ready() -> void:
	add_to_group("enemy")
	current_health = max_health
	sprite_mop.play("idel")
	damage_zone.area_entered.connect(_on_damage_zone_area_entered)

# -------------------------------
# Physics Process
# -------------------------------
func _physics_process(delta: float) -> void:
	# หา player ครั้งแรก
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]

	match state:
		State.IDLE:
			_play("idel")
			if player_ref and global_position.distance_to(player_ref.global_position) <= detect_range:
				_start_float()

		State.FLOAT:
			_play("idel")
			if player_ref:
				var target_pos = player_ref.global_position + Vector2(0, -float_height)
				global_position = global_position.lerp(target_pos, delta * 5)

		State.SHAKE:
			_play("hit")
			position.x += randf_range(-shake_strength, shake_strength)
			position.y += randf_range(-shake_strength, shake_strength)

		State.DASH:
			_play("walk")
			var direction = (dash_target - global_position).normalized()
			velocity = direction * dash_speed
			move_and_slide()

		State.REST:
			_play("idel")
			velocity = Vector2.ZERO

		State.HIT:
			_play("hit")

		State.DEAD:
			queue_free()

# -------------------------------
# Transition Logic
# -------------------------------
func _start_float() -> void:
	state = State.FLOAT
	await get_tree().create_timer(float_time).timeout

	state = State.SHAKE
	await get_tree().create_timer(shake_time).timeout

	if player_ref:
		dash_target = player_ref.global_position
	state = State.DASH

	# เข้าสู่ REST หลังพุ่งเสร็จ
	await get_tree().create_timer(0.5).timeout
	if state == State.DASH:
		_start_rest()

func _start_rest() -> void:
	state = State.REST
	await get_tree().create_timer(rest_time).timeout
	# ถ้าไม่ได้ถูกขัดด้วย HIT ระหว่างพัก → เริ่มลอยใหม่
	if state == State.REST and player_ref and player_ref.is_inside_tree():
		_start_float()

# -------------------------------
# Damage Zone
# -------------------------------
func _on_damage_zone_area_entered(area: Area2D) -> void:
	if area.name == "AttackZone":
		return

	var player_node = area.get_parent()
	while player_node and not player_node.is_in_group("player"):
		player_node = player_node.get_parent()

	if player_node:
		var player = player_node
		player_ref = player
		player.take_damage(damage_to_player)

# -------------------------------
# Damage / Die
# -------------------------------
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

	# ถ้าโดนตีตอน REST → ลอยขึ้นไปเลย
	if state == State.HIT and player_ref and player_ref.is_inside_tree():
		_start_float()
	else:
		state = State.IDLE

func die() -> void:
	state = State.DEAD
	_play("hit") # หรือ "die"
	await sprite_mop.animation_finished
	queue_free()

# -------------------------------
# Animation helper
# -------------------------------
func _play(name: String) -> void:
	if sprite_mop.animation != name:
		sprite_mop.play(name)
