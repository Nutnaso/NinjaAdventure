extends CanvasLayer

signal dialog_finished

func load_dialog(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var dialog_data = JSON.parse_string(file.get_as_text())
		# TODO: โหลดข้อมูลลง RichTextLabel/Label ตามที่คุณทำ
		_show_dialog(dialog_data)
		file.close()

func _show_dialog(data):
	# แสดงข้อความทีละบรรทัด (ตามระบบคุณ)
	# พอจบทั้งหมด ให้ emit signal
	emit_signal("dialog_finished")
