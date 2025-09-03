@icon("../character/icon_character.png")
extends CharacterBody2D


enum State { IDLE, ATTACKING }

signal teleported
signal died
signal health_changed(current_health: int, max_health: int)

@export_category("physics")
@export var speed: float = 150
@export var acceleration: float = 1000.0
@export var deceleration: float = 800.0

@export_category("stats")
@export var max_health: int = 100
@export var invincible_time: float = 1.0
@export var attack_power: int = 10
@export var attack_duration: float = 0.3

var current_health: int
var invincible: bool = false
var state: State = State.IDLE
var just_teleport := false
var can_move: bool = true



var move_vector := Vector2.ZERO:
	set(v):
		move_vector = v
		if move_vector.length():
			sprite.direction = move_vector.normalized()

@onready var sprite: SpriteCharacter = $Sprite
@onready var damage_zone: Area2D = $DamageZone
@onready var attack_zone: Area2D = $AttackZone

func _ready() -> void:
	current_health = max_health
	attack_zone.monitoring = false
	add_to_group("player")
	#attack_zone.area_entered.connect(_on_attack_zone_area_entered)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# ตรวจสอบสามารถขยับหรือไม่
	if can_move:
		move_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if Input.is_action_just_pressed("ui_accept"):
			start_attack()
			
	else:
		move_vector = Vector2.ZERO


	match state:
		State.IDLE:
			if move_vector.length():
				sprite.anim = SpriteCharacter.Anim.MOVING
				velocity = velocity.move_toward(move_vector * speed, acceleration * delta)
			else:
				sprite.anim = SpriteCharacter.Anim.IDLE
				velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
		State.ATTACKING:
			sprite.anim = SpriteCharacter.Anim.ATTACKING
			velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)

	_update_attack_zone()
	move_and_slide()

# ---------------------------
# ระบบโจมตี
# ---------------------------
func start_attack() -> void:
	if state == State.ATTACKING:
		return
	$Punch.play()
	state = State.ATTACKING
	attack_zone.monitoring = true
	_attack_wait()

func _attack_wait() -> void:
	await get_tree().create_timer(attack_duration).timeout
	state = State.IDLE
	attack_zone.monitoring = false

func _update_attack_zone() -> void:
	if sprite.direction == Vector2.UP:
		attack_zone.rotation_degrees = -90
	elif sprite.direction == Vector2.DOWN:
		attack_zone.rotation_degrees = 90
	elif sprite.direction == Vector2.LEFT:
		attack_zone.rotation_degrees = 180
	elif sprite.direction == Vector2.RIGHT:
		attack_zone.rotation_degrees = 0

func _on_attack_zone_area_entered(area: Area2D) -> void:
	print(area)
	# หา Enemy จริง จากโครงสร้าง Node
	var node = area.get_parent()
	while node and not node.is_in_group("enemy"):
		node = node.get_parent()
	if node:
		var enemy = node
		if enemy and enemy.has_method("take_damage") and state == State.ATTACKING:
			print("✅ Player attack hit enemy: ", enemy.name)
			enemy.take_damage(attack_power)

# ---------------------------
# ระบบเลือด
# ---------------------------
func take_damage(amount: int) -> void:
	if invincible:
		return
	
	$GetHit.play()
	current_health -= amount
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		current_health = 0
		die()
		return

	invincible = true
	sprite.modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(invincible_time).timeout
	invincible = false
	sprite.modulate = Color(1, 1, 1)

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func die() -> void:
	died.emit()
	queue_free()

## ---------------------------
## Teleport
## ---------------------------
#func teleport(target_teleporter: Teleporter, offset_position: Vector2):
	#if just_teleport:
		#return
	#global_position = target_teleporter.global_position + offset_position + (target_teleporter.direction * Vector2(25, 25))
	#just_teleport = true
	#for camera in get_tree().get_nodes_in_group("camera"):
		#camera.teleport_to(global_position)
	#await get_tree().create_timer(0.1, false).timeout
	#just_teleport = false
	#teleported.emit()
