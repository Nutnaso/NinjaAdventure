extends CharacterBody2D

@export var max_health: int = 50
var current_health: int

@export var damage_to_player: int = 10
@export var invincible_time: float = 0.5
@onready var sprite_mop: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_zone: Area2D = $DamageZone

var invincible: bool = false

enum State { IDLE, WALK, HIT, DEAD }
var state: State = State.IDLE

func _ready() -> void:
	add_to_group("enemy")
	current_health = max_health
	sprite_mop.play("idel")
	damage_zone.area_entered.connect(_on_damage_zone_area_entered)
	

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE: _play("idel")
		State.WALK: _play("walk")
		State.HIT: _play("hit")
		State.DEAD: queue_free()

# Player เข้ามาใน DamageZone → ลด HP Player
func _on_damage_zone_area_entered(area: Area2D) -> void:
	# ตรวจสอบว่า Area ที่เข้ามาคือ AttackZone ของ Player
	if area.name == "AttackZone":
		return

	# หา Node Player จริง
	var player_node = area.get_parent()
	while player_node and not player_node.is_in_group("player"):
		player_node = player_node.get_parent()

	if player_node:
		var player = player_node
		if player:
			print("✅ Enemy hit by player:", player.name)
			player.take_damage(damage_to_player)


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
	queue_free()

func _play(name: String) -> void:
	if sprite_mop.animation != name:
		sprite_mop.play(name)
 
