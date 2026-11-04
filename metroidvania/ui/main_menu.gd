class_name MainMenu extends Control

# Temporary main menu. Only starts a run for now, more buttons (options,
# controls, credits...) can be added to the ButtonsContainer later.

@export_file( "*.tscn" ) var first_level : String = "res://levels/00_school/01.tscn"

@onready var start_button : Button = %StartButton

func _ready() -> void:
	start_button.pressed.connect( _on_start_pressed )
	start_button.grab_focus()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file( first_level )
