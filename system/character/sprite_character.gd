extends Sprite2D
class_name SpriteCharacter

# -------------------------------
# Enum สำหรับ Animation
# -------------------------------
enum Anim {IDLE, MOVING, ATTACKING, JUMP, DEAD, ITEM, ABILITY, ABILITY_2}
enum FrameDirection {RIGHT=3, DOWN=0, LEFT=2, UP=1}

const IMAGE_SPEED := 6

# Animation frames mapping
const ANIMATION_DATA := {
	Anim.IDLE: [0],
	Anim.MOVING: [0,1,2,3],
	Anim.ATTACKING: [4],   # แก้ชื่อให้ตรงกับ Character
	Anim.JUMP: [5],
	Anim.DEAD: [6],
	Anim.ITEM: [6],
	Anim.ABILITY: [6],
	Anim.ABILITY_2: [6],
}

# -------------------------------
# ตัวแปร resource
# -------------------------------
var resource_character: ResourceCharacter:
	set(v):
		resource_character = v
		if !resource_character:
			return
		if !is_inside_tree():
			await ready

# -------------------------------
# ตัวแปร Animation
# -------------------------------
var anim: Anim = Anim.IDLE:
	set(v):
		if anim == v:
			return
		anim = v
		current_image = 0.0
		image_list = ANIMATION_DATA[anim]
		update_animation()

var direction := Vector2.DOWN:
	set(v):
		direction = v
		update_animation()

var image_list: PackedInt32Array = [0]:
	set(v):
		image_list = v

var current_image := 0.0:
	set(v):
		current_image = wrap(v, 0, max(image_list.size(), 1))
		update_animation()

# -------------------------------
# Animation update
# -------------------------------
func update_animation():
	frame_coords.x = direction_to_frame(direction)
	frame_coords.y = image_list[floor(current_image)]

func _process(delta: float) -> void:
	if image_list.size() > 1:
		current_image += IMAGE_SPEED * delta

# -------------------------------
# แปลงทิศทางเป็น frame
# -------------------------------
func direction_to_frame(direction: Vector2) -> int:
	match anim:
		Anim.DEAD:
			return 0
		Anim.ITEM:
			return 1
		Anim.ABILITY:
			return 2
		Anim.ABILITY_2:
			return 3
		_:
			var deg_angle := rad_to_deg(direction.angle())
			var angle_to_int: int = round(deg_angle / 90)
			var angle: int = wrap(angle_to_int, 0, 4)
			return FrameDirection.values()[angle]
