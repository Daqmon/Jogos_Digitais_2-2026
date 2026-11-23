class_name SettingsPanel extends PanelContainer
signal closed

@onready var fullscreen_button : Button = %FullscreenButton
@onready var volume_button : Button = %VolumeButton
@onready var back_button : Button = %BackButton

func _ready() -> void:
	fullscreen_button.pressed.connect( _on_fullscreen_pressed )
	volume_button.pressed.connect( _on_volume_pressed )
	volume_button.gui_input.connect( _on_volume_gui_input )
	back_button.pressed.connect( close )
	_refresh()

func open() -> void:
	_refresh()
	show()
	fullscreen_button.grab_focus()

func close() -> void:
	hide()
	closed.emit()

func _unhandled_input( event: InputEvent ) -> void:
	if visible and event.is_action_pressed( "ui_cancel" ):
		get_viewport().set_input_as_handled()
		close()

func _refresh() -> void:
	fullscreen_button.text = "TELA CHEIA: %s" % _on_off( GameSettings.fullscreen )
	volume_button.text = "VOLUME: %d%%" % GameSettings.volume

func _on_off( value : bool ) -> String:
	return "SIM" if value else "NÃO"

func _commit() -> void:
	GameSettings.apply()
	GameSettings.save()
	_refresh()

func _on_fullscreen_pressed() -> void:
	GameSettings.fullscreen = not GameSettings.fullscreen
	_commit()

func _on_volume_pressed() -> void:
	GameSettings.volume = ( GameSettings.volume + 10 ) % 110
	_commit()

func _on_volume_gui_input( event : InputEvent ) -> void:
	if event.is_action_pressed( "ui_left" ):
		GameSettings.volume = maxi( GameSettings.volume - 10, 0 )
		_commit()
		volume_button.accept_event()
	elif event.is_action_pressed( "ui_right" ):
		GameSettings.volume = mini( GameSettings.volume + 10, 100 )
		_commit()
		volume_button.accept_event()
