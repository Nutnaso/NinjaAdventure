extends Node2D

@onready var head = $Head
@onready var body_container = $BodyContainer

var body_segments = []
var segment_count = 20        # รวม BodyEnd
var segment_spacing = 25     # ระยะห่างระหว่าง segment

var position_history = []    # เก็บตำแหน่งหัวย้อนหลัง
var distance_accum = 0.0     # ตัวสะสมระยะ

var speed = 500

# โหลด texture ล่วงหน้า
var tex_body1 = preload("res://nut/Body1.png")
var tex_body2 = preload("res://nut/Body2.png")
var tex_body_end = preload("res://nut/BodyEnd.png")

func _ready():
	spawn_body()
	# เริ่มต้น position_history ด้วยตำแหน่งหัว
	position_history.append(head.position)

func spawn_body():
	for i in range(segment_count):
		var segment = Sprite2D.new()
		if i == segment_count - 1:
			segment.texture = tex_body_end
		else:
			segment.texture = tex_body1 if i % 2 == 0 else tex_body2

		body_container.add_child(segment)
		body_segments.append(segment)


func _process(delta):
	var old_pos = head.position
	move_head(delta)
	var moved = head.position.distance_to(old_pos)

	# เก็บตำแหน่งหัวก็ต่อเมื่อเคลื่อนที่เกิน 1 pixel
	distance_accum += moved
	while distance_accum >= 1.0:
		position_history.insert(0, head.position)
		distance_accum -= 1.0

	# จำกัดความยาว history
	var max_len = segment_count * segment_spacing + 1
	if position_history.size() > max_len:
		position_history.resize(max_len)

	update_body()

func move_head(delta):
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	if direction != Vector2.ZERO:
		head.position += direction.normalized() * speed * delta

func update_body():
	for i in range(body_segments.size()):
		var index = (i + 1) * segment_spacing
		if index < position_history.size():
			body_segments[i].position = position_history[index]

			# ===== หมุนตามทิศทาง =====
			# ถ้าไม่ใช่หาง ให้หมุนตามจุดก่อนหน้า
			if i < body_segments.size() - 1:
				var prev_index = index - 1
				if prev_index >= 0 and prev_index < position_history.size():
					var dir = position_history[prev_index] - position_history[index]
					body_segments[i].rotation = dir.angle()
			else:
				# หาง: หมุนตามทิศทางจากหางไปยัง segment ก่อนหน้า
				var prev_pos = body_segments[i - 1].position
				var dir = prev_pos - body_segments[i].position
				body_segments[i].rotation = dir.angle()
