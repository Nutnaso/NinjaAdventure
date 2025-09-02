extends CanvasLayer

@onready var name_label = $Panel/Label
@onready var text_label = $Panel/RichTextLabel
@onready var next_button = $Panel/Button

var dialog_data = []
var current_index = 0

func _ready():
	load_dialog("res://dialog.json")
	show_line(0)
	next_button.pressed.connect(_on_next_pressed)

func load_dialog(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.parse_string(content)
		if typeof(json) == TYPE_DICTIONARY:
			dialog_data = json["dialogs"]

func show_line(index: int):
	if index < dialog_data.size():
		var line = dialog_data[index]
		name_label.text = line["name"]
		text_label.text = line["text"]
	else:
		hide() # ซ่อนกล่องเมื่อจบบทสนทนา

func _on_next_pressed():
	current_index += 1
	show_line(current_index)

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"): # Enter หรือ Space
		_on_next_pressed()
