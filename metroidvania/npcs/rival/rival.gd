extends Node2D

@export var portrait : Texture2D
@export var dialogue_lines : Array[String]


func interact() -> void:
	print("The Rival's interact function was triggered!")
	if dialogue_lines.size() > 0:
		DialogueManager.start_dialogue(portrait, dialogue_lines)
