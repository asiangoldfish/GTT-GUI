class_name RequestLoader extends RefCounted

static var requests: Dictionary = {}

static var is_initialised: bool = false

static func initialise() -> void:
    if is_initialised:
        print("Tried to initialise RequestLoader, but it is already initialised")
    else:
        print("Initialising RequestLoader")
        
        if FileAccess.file_exists(Constants.requests_save):
            var file = FileAccess.open(Constants.requests_save, FileAccess.READ)
            #while file.get_position() < file.get_length():
            var json_string = file.get_as_text(true)

            var json = JSON.new()
            var error = json.parse(json_string)
            if error == OK:
                var data_received = json.data
                if typeof(data_received) == TYPE_DICTIONARY:
                    for data in data_received:
                        requests[data] = data_received.get(data)
                else:
                    print("Unexpected data")
            else:
                print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
                is_initialised = true

static func get_request(request_id: String):
    return requests.get(request_id)

static func save_request(request_id: String, request_dict: Dictionary):
    requests[request_id] = request_dict

    var save_file = FileAccess.open(Constants.requests_save, FileAccess.WRITE)
    var json_string = JSON.stringify(requests, "\t")
    save_file.store_line(json_string)

