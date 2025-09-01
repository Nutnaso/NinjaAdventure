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
@export var detect_range: float = 200.0
@export var dash_speed: float = 70
@export var pause_time: float = 0.5

# ---------------------------
# Nodes
# ---------------------------
@onready var sprite_mop: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_zone: Area2D = $DamageZone

# ---------------------------
# State
# ---------------------------
var invincible: bool = false

enum State { IDLE, DASH, PAUSE, HIT, DEAD }
var state: State = State.IDLE

var player: CharacterBody2D
var dash_direction := Vector2.ZERO
var dash_count: int = 0
var max_dash_count: int = 3  # พุ่งต่อเนื่อง 3 ครั้ง

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
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

	match state:
		State.IDLE:
			_play("idel")
			if player and global_position.distance_to(player.global_position) < detect_range:
				state = State.DASH
				dash_count = 0
				dash_direction = (player.global_position - global_position).normalized()

		State.DASH:
			if dash_count < max_dash_count:
				_play("walk")
				velocity = dash_direction * dash_speed
				move_and_slide()
				await get_tree().create_timer(0.4).timeout  # ระยะพุ่งแต่ละครั้ง
				velocity = Vector2.ZERO
				dash_count += 1

				# อัปเดตทิศทางใหม่แต่ยังคงพุ่งต่อ
				if player:
					dash_direction = (player.global_position - global_position).normalized()
			else:
				state = State.PAUSE
				dash_count = 0

		State.PAUSE:
			_play("idel")
			velocity = Vector2.ZERO
			await get_tree().create_timer(pause_time).timeout
			state = State.DASH
			if player:
				dash_direction = (player.global_position - global_position).normalized()

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
	_play("hit")
	await sprite_mop.animation_finished
	queue_free()

func _play(name: String) -> void:
	if sprite_mop.animation != name:
		sprite_mop.play(name)
