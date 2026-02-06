extends Control

@onready var manual_label: Label = find_child("ManualTextLabel")

func _ready():
    var file = FileAccess.open("res://manual.txt", FileAccess.READ)
    print(file.get_as_text())
    print(manual_label)
    manual_label.text = file.get_as_text()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("back"):
        get_tree().change_scene_to_file("res://screens/main_menu.tscn")