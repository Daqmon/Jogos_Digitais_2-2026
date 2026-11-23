class_name MainMenu extends Control

@export_file( "*.tscn" ) var first_level : String = "res://levels/00_school/01.tscn"

@onready var title_box : VBoxContainer = %TitleBox
@onready var out_label : Label = %OutLabel
@onready var main_buttons : VBoxContainer = %MainButtons
@onready var start_button : Button = %StartButton
@onready var settings_button : Button = %SettingsButton
@onready var controls_button : Button = %ControlsButton
@onready var settings_panel : SettingsPanel = %SettingsPanel
@onready var controls_panel : ControlsPanel = %ControlsPanel
@onready var hint_label : Label = %HintLabel
@onready var fog : Sprite2D = %Fog
@onready var hero : Sprite2D = %Hero
@onready var fade : ColorRect = %Fade

var _starting : bool = false

func _ready() -> void:
	GameSettings.load_settings()
	start_button.pressed.connect( _on_start_pressed )
	settings_button.pressed.connect( _open_panel.bind( settings_panel, settings_button ) )
	controls_button.pressed.connect( _open_panel.bind( controls_panel, controls_button ) )
	settings_panel.closed.connect( _on_panel_closed.bind( settings_button ) )
	controls_panel.closed.connect( _on_panel_closed.bind( controls_button ) )
	start_button.grab_focus()
	_play_intro()
func _on_start_pressed() -> void:
	if _starting:
		return
	_starting = true
	var tween : Tween = create_tween()
	tween.tween_property( fade, "color:a", 1.0, 0.4 )
	tween.tween_callback( get_tree().change_scene_to_file.bind( first_level ) )

func _open_panel( panel : Control, _opener : Button ) -> void:
	main_buttons.hide()
	title_box.hide()
	hint_label.hide()
	panel.open()

func _on_panel_closed( opener : Button ) -> void:
	main_buttons.show()
	title_box.show()
	hint_label.show()
	opener.grab_focus()

func _play_intro() -> void:
	fade.color.a = 1.0
	create_tween().tween_property( fade, "color:a", 0.0, 0.6 )
	var delay : float = 0.25
	for button in main_buttons.get_children():
		button.modulate.a = 0.0
		var final_x : float = button.position.x
		button.position.x -= 24.0
		var tween : Tween = create_tween().set_parallel()
		tween.tween_property( button, "modulate:a", 1.0, 0.25 ).set_delay( delay )
		tween.tween_property( button, "position:x", final_x, 0.25 ).set_delay( delay ).set_trans( Tween.TRANS_BACK ).set_ease( Tween.EASE_OUT )
		delay += 0.1
