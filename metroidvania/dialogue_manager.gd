extends Node

var dialogue_ui : CanvasLayer = null

var current_portrait : Texture2D
var current_lines : Array[String] = []
var current_index : int = 0
var is_active : bool = false

func _ready() -> void:
	# This tells Godot: "Even if the game pauses, keep listening for inputs!"
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_dialogue(portrait: Texture2D, lines: Array[String]) -> void:
	if is_active or dialogue_ui == null:
		return # Prevent starting a new conversation if one is already active

	current_portrait = portrait
	current_lines = lines
	current_index = 0
	is_active = true
	
	# Pause the game so enemies don't attack while the player is reading
	get_tree().paused = true 
	
	# Send the first line of text to the UI
	dialogue_ui.show_dialogue(current_portrait, current_lines[current_index])

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
		
	# Consume the pause button so the pause menu doesn't hear it
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		
	if event.is_action_pressed("up"):
		get_viewport().set_input_as_handled() 
		_advance_dialogue()

func _advance_dialogue() -> void:
	current_index += 1
	if current_index < current_lines.size():
		# Send the next line in the array to the UI
		dialogue_ui.show_dialogue(current_portrait, current_lines[current_index])
	else:
		_end_dialogue()

func _end_dialogue() -> void:
	is_active = false
	dialogue_ui.hide()
	get_tree().paused = false # Unpause the game
