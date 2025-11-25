extends Button
class_name RequestButton

signal request_was_selected

var request_id: String = ""
var request_name: String = "New request"

func set_request_name(s: String) -> void:
    request_name = s
    self.text = s

func _on_button_down() -> void:
    request_was_selected.emit(request_id)
