extends Control

@onready var name_labels = find_child("NameLabels")
@onready var time_labels = find_child("NameValues")

@onready var content_container: VBoxContainer = find_child("ContentContainer")

@onready var contributors_menu: OptionButton = find_child("ContributorsMenu")
@onready var plot_type_menu: OptionButton = find_child("PlotTypeMenu")

var participants: Dictionary

var contributors = {}    # Removed duplicated contributors
var cache = []

# Chart
var chart: Chart

func _ready() -> void:
    # Initialise the chart
    var chart_scene: PackedScene = load("res://addons/easy_charts/control_charts/chart.tscn")
    chart = chart_scene.instantiate()
    content_container.add_child(chart)
    chart.hide()

func initialise(c: Array) -> void:
    assert(not c.is_empty(), "Cache is empty")
    cache = c

    _sync_contributors()

    contributors_menu.clear()
    # Add empty entry
    contributors_menu.add_item("Select a contributor", 0)
    for key in contributors:
        var username = contributors[key]
        contributors_menu.add_item(username, key)

# This method synchronises contributors.
#
# The method must be called at least onece, so the menu knows which contributors
# to show.
func _sync_contributors():
    contributors.clear()

    # Get contributors
    var usernames = []
    for issue in cache:
        if not issue.get("timelogs") or not issue.get("timelogs").get("nodes"):
            continue

        var entries = issue.get("timelogs").get("nodes")
        for entry in entries:
            if entry.get("user") and entry.get("user").get("username"):
                var username = entry.get("user").get("username")
                # Make sure they aren't already registered
                if username not in usernames:
                    usernames.append(username)

    # Construct the member variable and dictionary contributors, so we can
    # easily use the OptionMenu ContributorsMenu to know which contributor we
    # are looking up.
    for i in len(usernames):
        contributors[i] = usernames[i]


# Show a plot for the contributor's time usage per issue
func _on_contributors_menu_item_selected(index: int) -> void:
    # The expected cache format is the following in JSON format:
    #[
    #   {
    #       "humanTimeEstimate": "3h",
    #       "iid": "80",
    #       "timeEstimate": 10800.0,
    #       "timelogs": {
    #           "nodes": [
    #               {
    #                   "spentAt": "2025-11-24T10:01:55Z",
    #                   "summary": "",
    #                   "timeSpent": 21600.0,
    #                   "user": {
    #                       "username": "USERNAME"
    #                   }
    #               }
    #           ]
    #       },
    #       "title": "[Story] Report: Abstract"
    #   },
    #   {...}
    #]

    if index <= 0:
        chart.hide()
        return

    # Key: issue ID. Value: total time spent for that particular issue in
    # seconds.
    var issue_time_tracked: Dictionary = {}
    var selected_contributor: String = contributors.get(index - 1)

    # Each issue can have multiple contributors and multiple entries per
    # contributor.
    var issue_id: int = 0
    for issue: Dictionary in cache:
        issue_time_tracked[issue_id] = 0
        # Issue has no registered time
        var timelog_entry = issue.get("timelogs").get("nodes")
        if timelog_entry.is_empty():
            pass
        else:
            # Find the total time spent for the selected contributor
            for entry in timelog_entry:
                var entry_username = entry.get("user").get("username")
                if selected_contributor == entry_username:
                    var time_spent = entry.get("timeSpent")

                    var hours = floori(time_spent / 3600.0)
                    #var remainder = hours % 3600
                    #var minutes = floor(remainder / 60.0)

                    issue_time_tracked[issue_id] += hours

        issue_id += 1


    # Plot the chart
    # More about easy-charts:
    # https://www.nicolosantilio.it/godot-engine.easy-charts/
    var function := Function.new(
        range(1, len(issue_time_tracked)),  # The function's X-values
        range(1, len(issue_time_tracked)).map(func(n): return issue_time_tracked.get(n)), # The function's Y-values
        "Hours",       # The function's name
        {
            type = Function.Type.BAR,       # The function's type
            marker = Function.Marker.SQUARE, # Some function types have additional configuraiton
            color = Color("#36a2eb"),        # The color of the drawn function
        }
    )

    var y_max_value = max_dict(issue_time_tracked)

    var cp := ChartProperties.new()
    cp.x_label = "Issue ID"
    cp.y_label = "Hours"
    cp.title = selected_contributor + "'s Hours per Issue"
    cp.show_legend = true
    cp.y_scale = y_max_value / 2
    cp.x_scale = len(issue_time_tracked) / 2

    # Set discrete y values
    chart.set_y_domain(0, y_max_value)
    chart.y_labels_function = func(value: int): return str(int(value))

    # Set discrete x values
    var x_max_value = len(issue_time_tracked)
    chart.set_y_domain(0, x_max_value)
    chart.x_labels_function = func(value: int): return str(int(value))

    # Plot the chart
    chart.plot([function], cp)

    chart.show()

# Get the max value in a dictionary
func max_dict(d: Dictionary) -> int:
    var m: int = 0
    for key in d:
        if d.get(key) > m:
            m = d.get(key)

    return m
