extends Control

@onready var http_request: HTTPRequest = find_child("HTTPRequest")

# Modes
@onready var content_panel = find_child("ContentPanel")
@onready var total_time_mode = find_child("TotalTime")
@onready var contributor_time_mode = find_child("ContributorTime")
@onready var sprint_time_mode = find_child("SprintTime")

var config: ConfigFile
var cache: Array

# Parameters used for visualisations
var participants = []

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("back"):
        get_tree().change_scene_to_file("res://screens/main_menu.tscn")

func _ready() -> void:
    http_request.request_completed.connect(_on_request_completed)

    config = ConfigFile.new()
    var err = config.load(Constants.config_path)
    if err != OK:
        print("main.gd:_ready(): Failed to read config \'" + Constants.config_path + "\'")

    # Load the cache, so we don't always have to send requests to analyse data
    load_cache([])


# Cache the results from the server.
#
# This method enables users to continuously analyse results without consuming
# additional bandwith of the server.
func sync():
    print("Synchronising with the GitLab server")

    var headers = [
        "Content-Type: application/json"
    ]

    var project_name = config.get_value("General", "project_id")

    # GraphQL
    var query = '{\"query\": \"query {project(fullPath: \\\"%s\\\") {issues{nodes{title iid timeEstimate humanTimeEstimate milestone{title iid} timelogs(first: 100000){nodes{summary timeSpent spentAt user{username}}}}}}}\"}' % project_name


    # We have to put the access token into the URL parameter
    assert(config.get_value("General", "url") != null, "URL is null!")
    assert(config.get_value("General", "token") != null, "Token is null!")

    var crafted_url = config.get_value("General", "url") + \
        "/api/graphql?access_token=" + \
        config.get_value("General", "token")

    # Verify the JSON request
    var json = JSON.new()
    if json.parse(query) == OK:
        http_request.request(crafted_url,
            headers,
            HTTPClient.METHOD_POST,
            query)
    else:
        printerr("The query is in incorrect JSON format!")


# Callback for a completed HTTP request.
func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    # For some reason, the request failed.
    # TODO add error handling like logging and prompt to ask users to recheck
    # the settings or test network connections.
    if result != HTTPRequest.RESULT_SUCCESS:
        print("HTTP request failed with code: ", response_code)
        return

    var text = body.get_string_from_utf8()
    # Attempt to JSONify. If it fails, just output the raw data.

    var json_data = JSON.parse_string(text)

    if json_data == null:
        print("Failed to parse the response")
        return

    # if json_data != null:
    #     # Convert the dictionary/array to pretty JSON for display
    #     output = JSON.stringify(json_data, "\t")
    # else:
    #     output = text

    # Results
    var gitlab_issues = json_data.get("data").get("project").get("issues").get("nodes")

    # Save the cache
    var of = FileAccess.open("res://cache.json", FileAccess.WRITE)
    of.store_line(JSON.stringify(gitlab_issues))

    # Reload cache so we have up-to-date data for visualisation
    load_cache(gitlab_issues)


# Load cache.
#
# If data is passed, then cache is read from this instead of reading from file.
# Dictionaries are passed by reference, making it more efficient than reading
# from file.
func load_cache(data: Array):
    print("Reloading cache")

    # Load from file
    if data.size() == 0:
        var cache_file = FileAccess.open(Constants.cache_path, FileAccess.READ)
        if cache_file != null:
            var json = JSON.new()
            var error = json.parse(cache_file.get_as_text())
            cache_file.close()
            if error == OK:
                cache = json.get_data()
    else:
        # Load from data argument
        cache = data

    # Each JSON object in `result` has a "timelogs.nodes" field. This is an
    # array. Each object inside this is a registered time and participants
    for issue in cache:
        if not issue.get("timelogs") or not issue.get("timelogs").get("nodes"):
            continue

        var entries = issue.get("timelogs").get("nodes")
        for entry in entries:
            if entry.get("user") and entry.get("user").get("username"):
                var username = entry.get("user").get("username")
                if not participants.has(username):
                    participants.append(username)

# This method hides all modes. It is useful to open a new mode.
func hide_all_modes() -> void:
    for child in content_panel.get_children():
        child.hide()

# Mode: Show total time
func _on_total_time_mode_btn_button_down() -> void:
    # Compute total time spent per person
    var total_time = {}
    for issue in cache:
        if not issue.get("timelogs") or not issue.get("timelogs").get("nodes"):
            continue

        var entries = issue.get("timelogs").get("nodes")
        for entry in entries:
            if entry.get("user") and entry.get("user").get("username"):
                var username = entry.get("user").get("username")
                var time_spent = entry.get("timeSpent")
                # If no entry, then create one
                if total_time.get(username) == null:
                    total_time[username] = time_spent
                else:
                    total_time[username] += time_spent


    hide_all_modes()
    total_time_mode.show()
    total_time_mode.populate(total_time)


# Show each contributor's time spent across all issues.
func _on_contributor_btn_button_down() -> void:
    ## The expected cache format is the following in JSON format:
    #[
    #   {
    #       "humanTimeEstimate": "3h",
    #       "iid": "80",
    #       "timeEstimate": 10800.0,
    #       "timelogs": {
    #           "nodes": []
    #       },
    #       "title": "[Story] Report: Abstract"
    #   },
    #   {...}
    #]
    # In short, it's an array of multiple JSON objects. Each object represents
    # a GitLab issue in DESCENDING order by issue ID.
    #
    # We send the entire dictionary array to the ContributorTime menu, it is
    # passed by reference and lets the menu deal with visualisation.
    hide_all_modes()
    contributor_time_mode.show()
    contributor_time_mode.initialise(cache)


func _on_sprint_time_btn_button_down() -> void:
    hide_all_modes()
    sprint_time_mode.show()
    sprint_time_mode.initialise(cache)
