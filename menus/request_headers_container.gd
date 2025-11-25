class_name RequestHeaders extends VBoxContainer

# A list of line edits. Each line edit represents a key in a header.
@onready var header_keys_collection = find_child("HeaderKeys")

# A list of header values. Each one is composed of an HBoxContainer with a LineEdit and a Button.
# The button is to delete the key-pair.
@onready var header_values_collection = find_child("HeaderValues")

func _ready() -> void:
    await get_tree().process_frame
    append("Hello", "world")

# Get all headers. This is not an inexpensive operation.
func get_header() -> Dictionary:
    return {}


func append(key: String, value: String):
    # Append key
    var k = LineEdit.new()
    k.text = key
    header_keys_collection.add_child(k)

    # Append value
    var v = LineEdit.new()
    v.text = value
    v.size_flags_horizontal = SIZE_EXPAND_FILL
    var del_btn = Button.new()
    del_btn.text = "🗑️"

    var hbox = HBoxContainer.new()
    hbox.add_child(v)
    hbox.add_child(del_btn)
    header_values_collection.add_child(hbox)


# Remove and clear the headers
func clear_headers():
    pass
