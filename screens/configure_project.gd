# This screen checks and prompts the user for required parameters like token,
# project id and url.

extends Control

# These are the states in prioritied order that will appear on the screen.
# If a state is not required, e.g. the user already has passed a url in the
# settings screen, then next state is active.
enum ConfigurationStates {
    URL = 0,
    TOKEN,
    PROJECT
}

var current_state = 0
# Last index in ConfigurationState
var max_state = 2

var config: ConfigFile

@onready var token_value: LineEdit = find_child("TokenValue")
@onready var project_value: LineEdit = find_child("ProjectValue")
@onready var url_value: LineEdit = find_child("UrlValue")

@onready var token_prompt: HBoxContainer = find_child("TokenPrompt")
@onready var url_prompt: HBoxContainer = find_child("UrlPrompt")
@onready var project_prompt: HBoxContainer = find_child("ProjectPrompt")


func _ready() -> void:
    url_prompt.hide()
    token_prompt.hide()
    project_prompt.hide()

    # Find the starting point
    config = ConfigFile.new()
    var err = config.load(Constants.config_path)
    if err == OK:
        if str(config.get_value("General", "url", "")).is_empty():
            current_state = 0
            url_prompt.show()
        elif str(config.get_value("General", "token", "")).is_empty():
            current_state = 1
            token_prompt.show()
        elif str(config.get_value("General", "project_id", "")).is_empty():
            current_state = 2
            project_prompt.show()
        else:
            # All is set! Go to main screen
            get_tree().change_scene_to_file("res://screens/main.tscn")

    else:
        current_state = 0


# TODO before changing state, check that the input is valid by prompting the
# server
func _on_next_btn_button_down() -> void:
    url_prompt.hide()
    token_prompt.hide()
    project_prompt.hide()

    # Save
    if current_state == 0:
        config.set_value("General", "url", url_value.text)
    elif current_state == 1:
        config.set_value("General", "token", token_value.text)
    elif current_state == 2:
        config.set_value("General", "project_id", project_value.text)
    
    load_next_state()


func load_next_state():
    var old_state = current_state
    current_state += 1

    # Load the next state
    if old_state == 0:
        # We are in url state. Go to token state
        if str(config.get_value("General", "token", "")).is_empty():
            token_prompt.show()
            return
    elif old_state == 1:
        # We are in token. Go to the project state
        if str(config.get_value("General", "project_id", "")).is_empty():
            project_prompt.show()
            return
    elif old_state >= max_state:
        config.set_value("General", "project_id", project_value.text)
        config.save(Constants.config_path)
        get_tree().change_scene_to_file("res://screens/main.tscn")
        return
    else:
        assert(false, "Config state is out of bounds!")
    
    load_next_state()

func _on_quit_btn_button_down() -> void:
    get_tree().change_scene_to_file("res://screens/main_menu.tscn")


func _on_value_text_submitted(_new_text: String) -> void:
    _on_next_btn_button_down()