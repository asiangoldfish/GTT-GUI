extends Control

class_name RequestMenu

@onready var address_bar = find_child("AddressBar")
@onready var http_request = $HTTPRequest
@onready var response_body = find_child("Response Body")
@onready var request_body = find_child("Request Body")
@onready var response_headers_container = find_child("ResponseHeadersContainer")
@onready var request_headers_container = find_child("RequestHeadersContainer")
@onready var send_request_btn = find_child("SendRequest")
@onready var dummy_address = find_child("DummyAddress")
@onready var title_edit = find_child("TitleEdit")
@onready var method_menu = find_child("MethodMenu")

# This is the same ID as the request it belongs to. See RequestBtn.id
@export var request_id: String = ""

# Name displayed on the request
@export var request_name: String = ""

signal title_was_changed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # HTTP methods dropdown menu
    method_menu.add_item("GET", HTTPClient.Method.METHOD_GET)
    method_menu.add_item("HEAD", HTTPClient.Method.METHOD_HEAD)
    method_menu.add_item("POST", HTTPClient.Method.METHOD_POST)
    method_menu.add_item("PUT", HTTPClient.Method.METHOD_PUT)
    method_menu.add_item("DELETE", HTTPClient.Method.METHOD_DELETE)
    method_menu.add_item("OPTIONS", HTTPClient.Method.METHOD_OPTIONS)
    method_menu.add_item("OPTIONS", HTTPClient.Method.METHOD_TRACE)
    method_menu.add_item("OPTIONS", HTTPClient.Method.METHOD_CONNECT)
    method_menu.add_item("PATCH", HTTPClient.Method.METHOD_PATCH)


    http_request.request_completed.connect(_on_request_completed)

    can_send_request(not request_id.is_empty())
        

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("save_request") and not request_id.is_empty():
        print("Request saved")
        save()


func can_send_request(check: bool) -> void:
    send_request_btn.disabled = not check
    dummy_address.disabled = not check
    address_bar.editable = check
    response_body.editable = check
    request_body.editable = check
    title_edit.editable = check


# Use this method to clear all inputs and text fields. Useful when switching
# requests.
func clear_all():
    address_bar.text = ""
    response_body.text = ""
    for n in response_headers_container.get_children():
        response_headers_container.remove_child(n)
        n.queue_free()

func _on_address_bar_text_submitted(url: String) -> void:
    if url.is_empty():
        print("Cannot send empty request")
    else:
        #print("Sending request")
        #print(request_body.text)
        print(JSON.parse_string(request_body.text))
        var test_headers = [
            "Content-Type: application/json"
        ]

#        http_request.set_timeout(10000)
        http_request.request(url, test_headers, method_menu.selected, request_body.text)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    # Print headers
    for n in response_headers_container.get_children():
        response_headers_container.remove_child(n)
        n.queue_free()

    for s in headers:
        var new_header = Label.new()
        new_header.text = s
        response_headers_container.add_child(new_header)

    if result == HTTPRequest.RESULT_SUCCESS:
        var text = body.get_string_from_utf8()
        # Attempt to JSONify. If it fails, just output the raw data.
        
        var json_data = JSON.parse_string(text)

        if json_data != null:
            # Convert the dictionary/array to pretty JSON for display
            response_body.text = JSON.stringify(json_data, "\t")
        else:
            response_body.text = text
    else:
        print("HTTP request failed with code: ", response_code)


func _on_send_request_button_down() -> void:
    _on_address_bar_text_submitted(address_bar.text)

func save():
    # Gather headers in a list
    var headers = []
    for label in response_headers_container.get_children():
        headers.append(label.text)

    var request_dict = {
        "name": request_name,
        "type": "request",
        "method": get_method(method_menu.selected),
        "url": address_bar.text,
        "response_body": response_body.text,
        "headers": headers,
        "request_body": request_body.text
    }

    RequestLoader.save_request(request_id, request_dict)

        
func _on_dummy_address_button_down() -> void:
    address_bar.text = Constants.mock_request


func _on_title_edit_text_submitted(new_text: String) -> void:
    request_name = new_text
    print("Title was changed to " + new_text)
    emit_signal("title_was_changed", request_id, new_text)

func load_request(id: String):
    can_send_request(true)
    request_id = id
    var req = RequestLoader.get_request(id)    
    if not req:
        print("Request was not found!")
    else:
        address_bar.text = req.get("url")
        response_body.text = req.get("response_body") if req.get("response_body") else ""
        title_edit.text = req.get("name")
        request_name = req.get("name")
        method_menu.selected = get_method_id(req.get("method"))
        request_body.text = req.get("request_body") if req.get("request_body") else ""
        for txt in req.get("headers"):
            var new_header = Label.new()
            new_header.text = txt
            response_headers_container.add_child(new_header)

func get_method(method_id: int) -> String:
    var method: String
    if method_id == HTTPClient.Method.METHOD_GET:
        method = "GET"
    elif method_id == HTTPClient.Method.METHOD_POST:
        method = "POST"
    elif method_id == HTTPClient.Method.METHOD_DELETE:
        method = "DELETE"
    elif method_id == HTTPClient.Method.METHOD_PUT:
        method = "PUT"
    elif method_id == HTTPClient.Method.METHOD_PATCH:
        method = "PATCH"
    elif method_id == HTTPClient.Method.METHOD_HEAD:
        method = "HEAD"
    elif method_id == HTTPClient.Method.METHOD_OPTIONS:
        method = "OPTIONS"

    return method

func get_method_id(method: String) -> int:
    var id = 0
    if method == "GET":
        id = HTTPClient.Method.METHOD_GET
    elif method == "POST":
        id = HTTPClient.Method.METHOD_POST
    elif method == "DELETE":
        id = HTTPClient.Method.METHOD_DELETE
    elif method == "PUT":
        id = HTTPClient.Method.METHOD_PUT
    elif method == "PATCH":
        id = HTTPClient.Method.METHOD_PATCH
    elif method == "HEAD":
        id = HTTPClient.Method.METHOD_HEAD
    elif method == "OPTIONS":
        id = HTTPClient.Method.METHOD_OPTIONS

    return id
