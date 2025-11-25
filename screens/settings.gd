extends Control

@onready var token_value = find_child("TokenValue")
@onready var project_value = find_child("ProjectValue")
@onready var url_value = find_child("UrlValue")

func _ready() -> void:
    # Populate fields from config file
    var config = ConfigFile.new()
    var err = config.load(Constants.config_path)
    if err != OK:
        print("settings.gd:_ready(): Failed to read config \'" + Constants.config_path + "\'")
    else:
        token_value.text = str(config.get_value("General", "token", ""))
        project_value.text = str(config.get_value("General", "project_id", ""))
        url_value.text = str(config.get_value("General", "url", ""))


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("back"):
        _on_back_btn_button_down()

func _on_back_btn_button_down() -> void:
    var config = ConfigFile.new()
    var err = config.load(Constants.config_path)
    if err != OK:
        print("settings.gd:_ready(): Failed to read config \'" + Constants.config_path + "\'")
    else:
        config.set_value("General", "token", token_value.text)
        config.set_value("General", "project_id", project_value.text)
        config.set_value("General", "url", url_value.text)
        config.save(Constants.config_path)
    get_tree().change_scene_to_file("res://screens/main_menu.tscn")

func _on_token_visibility_toggle_button_down() -> void:
    token_value.secret = !token_value.secret