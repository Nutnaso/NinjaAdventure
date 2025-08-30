extends CharacterBody2D

@export var max_health: int = 50
var current_health: int

@export var damage_to_player: int = 10  # จำนวนเลือดที่ทำให้ผู้เล่นลด
@export var invincible_time: float = 0.5 # เวลาที่ไม่สามารถโดน damage ซ้ำ
@onready var sprite_mop: AnimatedSprite2D = $AnimatedSprite2D

var invincible: bool = false

enum State { IDLE, WALK, HIT, DEAD }
var state: State = State.IDLE

func _ready() -> void:
	current_health = max_health
	sprite_mop.play("idel") # เริ่มต้นด้วย idle


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			_play("idel")
		State.WALK:
			_play("walk")
		State.HIT:
			_play("hit")
		State.DEAD:
			queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if invincible:
		return

	if body is Character:
		var player = body as Character
		player.take_damage(damage_to_player)
		if player.state == Character.State.ATTACKING:
			take_damage(player.attack_power)


func take_damage(amount: int) -> void:
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
	_play("hit")  # หรือทำ animation die แยกก็ได้
	await sprite_mop.animation_finished
	queue_free()


# ฟังก์ชันเล็ก ๆ กัน reset animation บ่อยเกินไป
func _play(name: String) -> void:
	if sprite_mop.animation != name:
		sprite_mop.play(name)
