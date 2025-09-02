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
@export var detect_range: float = 100
@export var orbit_radius: float = 100.0       # ระยะโคจรรอบผู้เล่น
@export var orbit_speed: float = 2.0          # ความเร็วโคจร (rad/s)
@export var orbit_clockwise: bool = true      # หมุนตามเข็มหรือทวนเข็ม
@export var shake_time: float = 2.0           # เวลาเตรียมพุ่ง
@export var dash_speed: float = 125           # ความเร็วพุ่ง
@export var pause_time: float = 4.0           # รอหลังพุ่ง

# ---------------------------
# Nodes
# ---------------------------
@onready var sprite_fire: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_zone: Area2D = $DamageZone

# ---------------------------
# State
# ---------------------------
var invincible: bool = false

enum State { IDLE, ORBIT, SHAKE, DASH, PAUSE, HIT, DEAD }
var state: State = State.IDLE

var player: CharacterBody2D
var orbit_angle: float = 0.0
var dash_target: Vector2 = Vector2.ZERO

# ---------------------------
# Ready
# ---------------------------
func _ready() -> void:
	add_to_group("enemy")
	current_health = max_health
	sprite_fire.play("idel")
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
				state = State.ORBIT
				orbit_angle = 0.0

		State.ORBIT:
			_play("walk")
			if player:
				# โคจรรอบผู้เล่น
				var direction = 1 if orbit_clockwise else -1
				orbit_angle += orbit_speed * delta * direction
				var offset = Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
				global_position = player.global_position + offset

				# หลังโคจรครบ 1 รอบ (2π rad)
				if orbit_angle >= PI*2 or orbit_angle <= -PI*2:
					# บันทึกตำแหน่งผู้เล่น **ก่อนเริ่ม SHAKE**
					dash_target = player.global_position
					state = State.SHAKE

		State.SHAKE:
			_play("walk")
			var shake_timer := 0.0
			while shake_timer < shake_time:
				var shake_offset = Vector2(randf()-0.5, randf()-0.5) * 0.4
				global_position += shake_offset
				await get_tree().process_frame
				shake_timer += get_process_delta_time()
			# หลังสั่นจบ เป้าหมายคือตำแหน่งสุดท้ายของผู้เล่นก่อนสั่น
			state = State.DASH

		State.DASH:
			_play("walk")
			var dir = (dash_target - global_position).normalized()
			velocity = dir * dash_speed
			move_and_slide()
			if global_position.distance_to(dash_target) < 10:
				velocity = Vector2.ZERO
				state = State.PAUSE

		State.PAUSE:
			_play("idel")
			velocity = Vector2.ZERO
			await get_tree().create_timer(pause_time).timeout
			state = State.ORBIT
			orbit_angle = 0.0

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

	state = State.ORBIT
	orbit_angle = 0.0

func die() -> void:
	state = State.DEAD
	_play("hit")
	await sprite_fire.animation_finished
	queue_free()

func _play(name: String) -> void:
	if sprite_fire.animation != name:
		sprite_fire.play(name)
