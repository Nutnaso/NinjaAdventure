@icon("../character/icon_character.png")
extends CharacterBody2D

@export var speed: float = 125
@export var acceleration: float = 800.0
@export var deceleration: float = 600.0
@export var detection_range: float = 50    # ระยะตรวจจับครั้งแรก
@export var min_distance: float = 25       # ระยะห่างที่ต้องการให้ NPC เว้นจากผู้เล่น

@onready var sprite: SpriteCharacter = $Sprite

var target_player: Node2D = null
var chasing: bool = false   # NPC เจอผู้เล่นแล้วหรือยัง

func _ready() -> void:
	# หาผู้เล่นจาก group "player"
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

func _physics_process(delta: float) -> void:
	if not target_player:
		return
	
	var to_player = target_player.global_position - global_position
	var distance = to_player.length()

	# เริ่มไล่ตามถ้าเข้าใกล้ครั้งแรก
	if not chasing and distance <= detection_range:
		chasing = true
	
	if chasing:
		if distance > min_distance:
			# ไล่ตามผู้เล่น แต่เว้นระยะ min_distance
			var direction = to_player.normalized()
			velocity = velocity.move_toward(direction * speed, acceleration * delta)
			sprite.anim = SpriteCharacter.Anim.MOVING
			sprite.direction = direction
		else:
			# อยู่ใกล้แล้ว → หยุด
			velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
			sprite.anim = SpriteCharacter.Anim.IDLE

	move_and_slide()
