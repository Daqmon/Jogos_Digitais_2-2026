class_name PauseMenu extends CanvasLayer

@export var enabled : bool = true # the Player turns it off when dead

@onready var menu_panel : PanelContainer = %MenuPanel
@onready var resume_button : Button = %ResumeButton
@onready var controls_button : Button = %ControlsButton
@onready var controls_panel : ControlsPanel = %ControlsPanel

func _ready() -> void:
	hide()
	resume_button.pressed.connect( resume )
	controls_button.pressed.connect( _on_controls_pressed )
	controls_panel.closed.connect( _on_controls_closed )

func _unhandled_input( event: InputEvent ) -> void:
	if DialogueManager.is_active:
		return
	if not enabled or not event.is_action_pressed( "pause" ):
		return
	get_viewport().set_input_as_handled()
	if controls_panel.visible:
		controls_panel.close()
	elif visible:
		resume()
	else:
		pause()

func pause() -> void:
	get_tree().paused = true
	menu_panel.show()
	controls_panel.hide()
	show()
	resume_button.grab_focus()

func resume() -> void:
	get_tree().paused = false
	hide()

func _on_controls_pressed() -> void:
	menu_panel.hide()
	controls_panel.open()

func _on_controls_closed() -> void:
	menu_panel.show()
	controls_button.grab_focus()

func _exit_tree() -> void:
	if get_tree():
		get_tree().paused = false
