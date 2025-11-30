extends Control

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("back"):
        get_tree().quit()

func _on_track_time_btn_button_down() -> void:
    get_tree().change_scene_to_file("res://screens/configure_project.tscn")


func _on_settings_btn_button_down() -> void:
    get_tree().change_scene_to_file("res://screens/settings.tscn")


func _on_quit_btn_button_down() -> void:
    get_tree().quit()
