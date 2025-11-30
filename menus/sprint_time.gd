extends Control

@onready var content_container: VBoxContainer = find_child("ContentContainer")

@onready var contributors_menu: OptionButton = find_child("ContributorsMenu")

var participants: Dictionary

var contributors = {}    # Removed duplicated contributors
var cache = []

# Chart
var chart: Chart

# An issue in the JSON response's top-level array can have the "milestone"
# field. If not null, then the issue belongs to that milestone. The milestone
# has "iid" and "title" fields. We use the "title" field to classify an issue's
# sprint association.
var sprint_titles = [
    "Sprint 1",
    "Sprint 2",
    "Sprint 3",
    "Sprint 4",
    "Sprint 5",
]

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
    #       "humanTimeEstimate": "HUMAN_HOURS_ESTIMATE",
    #       "iid": "ISSUE_ID",
    #       "milestone": {
    #           "iid": "MILESTONE_ID",
    #           "title": "MILESTONE_NAME"
    #       },
    #       "timeEstimate": SECONDS_ESTIMATED,
    #       "timelogs": {
    #           "nodes": [
    #               {
    #                   "spentAt": "DATE",
    #                   "summary": "",
    #                   "timeSpent": TIME_SPENT,
    #                   "user": {
    #                       "username": "USERNAME"
    #                   }
    #               }
    #           ]
    #       },
    #       "title": "ISSUE_TITLE"
    #   },
    #   {...}
    #]

    if index <= 0:
        chart.hide()
        return

    # Key: issue ID. Value: total time spent for that particular issue in
    # seconds.
    var sprint_time_tracked: Dictionary = {}
    var selected_contributor: String = contributors.get(index - 1)

    # Reset sprint tracked times
    for title in sprint_titles:
        sprint_time_tracked[title] = 0

    # Each issue can have multiple contributors and multiple entries per
    # contributor.
    var issue_id: int = 0
    for issue: Dictionary in cache:
        var milestone_title: String = ""
        # The issue has no milestone
        if not issue.get("milestone"):
            issue_id += 1
            continue
        else:
            # Set the milestone title
            if not issue.get("milestone").get("title").is_empty():
                milestone_title = issue.get("milestone").get("title")

        # The milestone title must be a valid sprint title
        if milestone_title not in sprint_titles:
            issue_id += 1
            continue

        # Issue has registered time
        var timelog_entry = issue.get("timelogs").get("nodes")
        if not timelog_entry.is_empty():
            # Find the total time spent for the selected contributor
            for entry in timelog_entry:
                var entry_username = entry.get("user").get("username")
                if selected_contributor == entry_username:
                    var time_spent = entry.get("timeSpent")
                    var hours = floori(time_spent / 3600.0)
                    sprint_time_tracked[milestone_title] += hours

        issue_id += 1

    var X = sprint_titles
    var Y = []
    for time in sprint_time_tracked:
        Y.append(sprint_time_tracked.get(time))

    # Plot the chart
    # More about easy-charts:
    # https://www.nicolosantilio.it/godot-engine.easy-charts/
    var function := Function.new(
        X,  # The function's X-values
        Y, # The function's Y-values
        "Hours",       # The function's name
        {
            type = Function.Type.BAR,       # The function's type
            marker = Function.Marker.SQUARE, # Some function types have additional configuraiton
            color = Color("#36a2eb"),        # The color of the drawn function
        }
    )

    var y_max_value = max_dict(sprint_time_tracked)

    var cp := ChartProperties.new()
    cp.x_label = "Issue ID"
    cp.y_label = "Hours"
    cp.title = selected_contributor + "'s Hours per Issue"
    cp.show_legend = true
    cp.y_scale = 10 #y_max_value / 2
    #cp.x_scale = len(sprint_time_tracked) / 2

    # Set discrete y values
    chart.set_y_domain(0, y_max_value)
    chart.y_labels_function = func(value: int): return str(int(value))

    # Set discrete x values
    #var x_max_value = len(sprint_time_tracked)
    #chart.set_y_domain(0, x_max_value)
    #chart.x_labels_function = func(value: int): return str(int(value))

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
