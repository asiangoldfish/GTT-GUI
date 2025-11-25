extends Control

@onready var name_labels = find_child("NameLabels")
@onready var time_labels = find_child("NameValues")

@onready var format_menu = find_child("FormatMenu")

var participants: Dictionary

func _ready() -> void:
    format_menu.add_item("Days-Hours-Minutes", 0)
    format_menu.add_item("Hours-Minutes", 1)

# Populate the names table
#
# Arguments:
#   p (Dictionary): participants
func populate(p: Dictionary):
    if not p.is_empty():
        participants = p

    # Clear all first
    for n in name_labels.get_children():
        name_labels.remove_child(n)
        n.queue_free()

    for n in time_labels.get_children():
        time_labels.remove_child(n)
        n.queue_free()

    var index = 0
    for username in participants:
        var seconds = participants[username]

        # Add name label
        var name_label: Label = Label.new()
        name_label.text = username
        name_labels.add_child(name_label)

        # Add time label
        var seconds_label: Label = Label.new()

        assert(format_menu.selected <= 1,
            "Format menu selection not implemented")

        match format_menu.selected:
            0:
                seconds_label.text = show_days_hours_minutes(seconds)
            1:
                seconds_label.text = show_hours_miuntes(seconds)
        time_labels.add_child(seconds_label)

        if index != participants.size() - 1:
            name_labels.add_child(HSeparator.new())
            time_labels.add_child(HSeparator.new())

        index += 1
    
func show_days_hours_minutes(seconds: int) -> String:
    # Work day is 7.5 hours in Norway, usually.
    # 60*60*7.5 = 27000
    var sec_in_workday = 60*60*7.5
    
    var days = floori(seconds / sec_in_workday)
    var remainder = int(seconds) % int(sec_in_workday)

    var hours = floori(remainder / 3600.0)
    remainder = hours % 3600
    
    var minutes = floori(remainder / 60.0)
    
    return str(days) + "d " + str(hours) + "h " + str(minutes) + "m"

func show_hours_miuntes(seconds: int) -> String:
    var hours = floori(seconds / 3600.0)
    var remainder = hours % 3600
    var minutes = floor(remainder / 60.0)
    return str(hours) + "h " + str(minutes) + "m"


func _on_format_menu_item_selected(_index: int) -> void:
    populate({})