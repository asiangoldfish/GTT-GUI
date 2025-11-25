extends MenuBar

@onready var file_menu = self.get_node("File")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Assuming 'file_menu' is the path to your PopupMenu node
    file_menu.add_item("Option 1", 0) # Add item with text "Option 1" and ID 0
    file_menu.add_item("Option 2", 1) # Add item with text "Option 2" and ID 1
    file_menu.add_separator() # Add a separator line
    file_menu.add_item("Quit", 99) 

func _on_file_id_pressed(id: int) -> void:
    if id == 99:
        get_tree().quit()
